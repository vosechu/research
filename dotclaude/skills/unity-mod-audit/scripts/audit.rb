#!/usr/bin/env ruby
# frozen_string_literal: true

# Static security audit of Unity mod assemblies. Never loads or runs a DLL: it decompiles with
# ilspycmd, then reads the C#. See ../SKILL.md.
# Usage: audit.rb [--skip-known] [--out DIR] [--max-sites N] PATH...
require 'digest'
require 'fileutils'
require 'open3'
require 'optparse'

module UnityModAudit
  class Error < StandardError; end

  Finding = Struct.new(:category, :severity, :file, :line, :text)
  Result = Struct.new(:name, :sha256, :findings, :notes, :resources, keyword_init: true)
  BinaryReport = Struct.new(:managed, :blocks, :high_blocks, :sections, :odd_sections, :embedded)

  SEVERITIES = %i[high medium low].freeze

  def self.words(*names) = /\b(?:#{names.join('|')})\b/

  SECRET_WORDS = Regexp.new(
    Regexp.union(%w[password passwd .ssh id_rsa loginusers config.vdf ssfn .aws cookie keychain
                    wallet.dat] + ['Login Data', 'Local State']).source, Regexp::IGNORECASE
  )

  # [category, severity, regex, where]. :code rules read the line with strings blanked; :strings
  # rules read only the string literals.
  RULES = [
    [:network, :high,
     Regexp.union(words('WebClient', 'HttpClient', 'HttpWebRequest', 'WebRequest', 'TcpClient',
                        'TcpListener', 'UdpClient', 'Socket', 'ClientWebSocket', 'WebSocket',
                        'UnityWebRequest\w*'), /System\.Net\b/), :code],
    [:process, :high, words('Process\.Start', 'ProcessStartInfo', 'ShellExecute\w*'), :code],
    [:links, :medium, words('Application\.OpenURL'), :code],
    [:native, :high,
     words('DllImport', 'LibraryImport', 'LoadLibrary\w*', 'GetProcAddress', 'NativeLibrary',
           'GetDelegateForFunctionPointer', 'dlopen'), :code],
    [:dynamic_code, :high,
     words('Assembly\.(?:Load\w*|UnsafeLoadFrom)', 'AppDomain', 'ILGenerator', 'DynamicMethod',
           'CSharpCodeProvider', 'Activator\.CreateInstanceFrom'), :code],
    [:il_patching, :low, words('OpCodes', 'CodeInstruction'), :code],
    [:files, :medium,
     Regexp.union(/\b(?:File|Directory)\.\w+\(/,
                  words('FileStream', 'StreamReader', 'StreamWriter', 'FileInfo', 'DirectoryInfo'),
                  /Application\.(?:persistentDataPath|dataPath|streamingAssetsPath)\b/), :code],
    [:environment, :medium,
     Regexp.union(/\bEnvironment\.(?:GetEnvironmentVariable\w*|UserName|MachineName|GetFolderPath|
                    GetCommandLineArgs|OSVersion)\b/x,
                  /SystemInfo\.(?:deviceUniqueIdentifier|deviceName)\b/,
                  words('Registry(?:Key)?')), :code],
    [:steam_auth, :high, /GetAuthSessionTicket|GetAuthTicketForWebApi/, :code],
    [:encoding, :medium,
     Regexp.union(/\bConvert\.(?:From|To)Base64String\b/,
                  words('GZipStream', 'DeflateStream', 'ZipArchive', 'Aes\w*', 'Rijndael\w*',
                        'RSA\w*'),
                  /\bGetString\(\s*new byte\b/, /\bnew string\(new char\[/), :code],
    [:threads, :low, /\bnew (?:Thread|Timer)\(|\bParallel\.|\bTask\.Run\b|\bThreadPool\b/, :code],
    [:secrets, :high, SECRET_WORDS, :strings]
  ].freeze

  STRING_LITERAL = /"(?:[^"\\]|\\.)*"/
  USING_DIRECTIVE = /\A\s*(?:global\s+)?using\s+(?:static\s+)?(?:\w+\s*=\s*)?[\w.]+\s*;\s*\z/

  # Findings for one source file. One finding per category per line.
  def self.scan_source(file, source)
    in_block = false
    source.each_line.with_index(1).flat_map do |raw, number|
      code, in_block = strip_comments(raw, in_block)
      next [] if code.strip.empty? || code.match?(USING_DIRECTIVE)

      views = { code: code.gsub(STRING_LITERAL, '""'),
                strings: code.scan(STRING_LITERAL).join(' ') }
      RULES.filter_map do |category, severity, pattern, where|
        Finding.new(category, severity, file, number, raw.strip) if views[where].match?(pattern)
      end
    end
  end

  # Returns [code_without_comments, still_inside_block_comment].
  def self.strip_comments(line, in_block)
    code = +''
    rest = line.dup
    until rest.empty?
      if in_block
        close = rest.index('*/')
        return [code, true] unless close

        rest = rest[(close + 2)..]
        in_block = false
      elsif (start = comment_start(rest))
        code << rest[0, start]
        return [code, false] if rest[start, 2] == '//'

        rest = rest[(start + 2)..]
        in_block = true
      else
        return [code << rest, false]
      end
    end
    [code, in_block]
  end

  # Index of the first // or /* that is outside a string literal, or nil.
  def self.comment_start(text)
    position = 0
    while position < text.size
      if text[position] == '"'
        literal = text[position..][STRING_LITERAL]
        position += literal ? literal.size : 1
      elsif %w[// /*].include?(text[position, 2])
        return position
      else
        position += 1
      end
    end
    nil
  end

  module Binary
    BLOCK = 4096
    MIN_BLOCK = 1024
    # Bits per byte. Compiled .NET sits near 5-6; compressed or encrypted data is above 7.5.
    HIGH_ENTROPY = 7.2
    STANDARD_SECTION = /\A\.(?:text|rsrc|reloc|data|rdata|idata|edata|pdata|tls|bss|xdata|didat|
                        debug|CRT)\z/x
    SIGNATURES = { 'zip' => "PK\x03\x04".b, 'gzip' => "\x1f\x8b\x08".b,
                   'elf' => "\x7fELF".b }.freeze

    def self.report(bytes)
      bytes = bytes.b
      rates = bytes.bytes.each_slice(BLOCK).map { |slice| slice.pack('C*') }
                   .select { |block| block.size >= MIN_BLOCK }.map { |block| entropy(block) }
      names = sections(bytes)
      high = rates.count { |rate| rate > HIGH_ENTROPY }
      BinaryReport.new(bytes.include?('BSJB'.b), rates.size, high, names,
                       names.grep_v(STANDARD_SECTION), embedded(bytes))
    end

    # Findings that say a DLL is packed, hides another file, or is not .NET at all.
    def self.findings(report, name)
      found = []
      unless report.managed
        found << Finding.new(:native_dll, :high, name, 0,
                             'not a .NET assembly (native code or not a DLL)')
      end
      if report.high_blocks.positive?
        text = "#{report.high_blocks}/#{report.blocks} blocks above #{HIGH_ENTROPY} bits per byte"
        found << Finding.new(:packed, :high, name, 0, text)
      end
      report.odd_sections.each do |section|
        found << Finding.new(:packed, :high, name, 0, "unusual PE section #{section}")
      end
      report.embedded.each do |kind|
        found << Finding.new(:embedded, :high, name, 0, "embedded #{kind} data")
      end
      found
    end

    def self.entropy(chunk)
      chunk.bytes.tally.values.sum do |count|
        share = count.fdiv(chunk.size)
        -share * Math.log2(share)
      end
    end

    def self.sections(bytes)
      pe = pe_offset(bytes, 0)
      return [] unless pe

      count = bytes[pe + 6, 2].unpack1('v')
      table = pe + 24 + bytes[pe + 20, 2].unpack1('v')
      Array.new(count) { |i| bytes[table + (i * 40), 8].to_s.delete("\0") }
    end

    # Offset of the "PE\0\0" header for a PE file that starts at base, or nil.
    def self.pe_offset(bytes, base)
      raw = bytes[base + 0x3c, 4]
      return unless raw&.size == 4 && bytes[base, 2] == 'MZ'

      header = raw.unpack1('V')
      pe = base + header
      pe if header < 0x1000 && bytes[pe, 4] == "PE\0\0".b
    end

    def self.embedded(bytes)
      kinds = []
      position = 1
      while (found = bytes.index('MZ'.b, position))
        if pe_offset(bytes, found)
          kinds << 'pe'
          break
        end
        position = found + 1
      end
      SIGNATURES.each { |kind, signature| kinds << kind if bytes.include?(signature) }
      kinds
    end
  end

  module Layout
    EXECUTABLE = { 'pe' => 'MZ', 'elf' => "\x7fELF", 'script' => '#!',
                   'macho' => "\xcf\xfa\xed\xfe".b }.freeze
    IMAGE = { '.png' => "\x89PNG\r\n\x1a\n".b, '.jpg' => "\xff\xd8\xff".b,
              '.jpeg' => "\xff\xd8\xff".b, '.gif' => 'GIF8', '.wav' => 'RIFF' }.freeze

    # Problems with the files in a mod folder, as "relative/path: what is wrong".
    def self.problems(dir)
      Dir.glob('**/*', File::FNM_DOTMATCH, base: dir).sort.flat_map do |relative|
        next [] if %w[. ..].include?(File.basename(relative))

        path = File.join(dir, relative)
        next ["#{relative}: symlink"] if File.symlink?(path)
        next [] if File.directory?(path)

        entry_problems(relative, path)
      end
    end

    def self.entry_problems(relative, path)
      found = []
      found << "#{relative}: hidden file" if File.basename(relative).start_with?('.')
      head = File.binread(path, 16).to_s
      extension = File.extname(path).downcase
      kind = EXECUTABLE.find { |_, magic| head.start_with?(magic.b) }&.first
      if kind
        found << "#{relative}: executable (#{kind})" unless extension == '.dll'
      elsif IMAGE.key?(extension) && !head.start_with?(IMAGE[extension].b)
        found << "#{relative}: not a real #{extension.delete('.')}"
      end
      found
    end
  end

  class Decompiler
    attr_reader :tool

    def self.locate(path: ENV.fetch('PATH', '').split(File::PATH_SEPARATOR), home: Dir.home)
      candidates = path.map { |dir| File.join(dir, 'ilspycmd') }
      candidates << File.join(home, '.dotnet/tools/ilspycmd')
      candidates.find { |file| File.executable?(file) } or
        raise Error, 'ilspycmd not found. Install it: dotnet tool install -g ilspycmd'
    end

    def initialize(tool:, runner: Open3.method(:capture3))
      @tool = tool
      @runner = runner
    end

    # Writes a compilable C# project for the assembly into out_dir.
    def call(dll, out_dir)
      _, error, status = @runner.call(@tool, '-p', '-o', out_dir, dll)
      raise Error, "ilspycmd failed on #{dll}: #{error.to_s.strip[0, 300]}" unless status.success?
    end

    def resources(dll)
      output, _, status = @runner.call(@tool, '--list-resources', dll)
      status.success? ? output.lines.map(&:strip).reject(&:empty?) : []
    end
  end

  KNOWN = /\A(?:System(?:\..*)?|Microsoft\..*|mscorlib|netstandard|UnityEngine(?:\..*)?|Unity\..*|
             Mono\..*|MonoMod.*|Newtonsoft\..*|0Harmony|Assembly-CSharp(?:-firstpass)?|
             BepInEx.*)\z/x

  # DLL paths under a folder, or the path itself if it is a file. skip_known drops framework, Unity
  # and Harmony assemblies by name. It is off by default because a mod could ship a DLL that
  # borrows a framework name.
  def self.discover(path, skip_known: false)
    return [path] if File.file?(path)

    relatives = Dir.glob('**/*.dll', File::FNM_CASEFOLD, base: path).sort
    found = relatives.map { |relative| File.join(path, relative) }
    skip_known ? found.reject { |dll| File.basename(dll, '.*').match?(KNOWN) } : found
  end

  def self.format_report(results, max_sites:)
    sorted = results.sort_by { |result| [severity_rank(result), result.name] }
    summary = sorted.map { |result| "  #{result.name}  #{worst(result)}" }
    details = sorted.flat_map { |result| result_lines(result, max_sites) }
    (['SUMMARY'] + summary + details).join("\n")
  end

  def self.severity_rank(result)
    SEVERITIES.index { |s| result.findings.any? { |f| f.severity == s } } || SEVERITIES.size
  end

  def self.worst(result)
    SEVERITIES[severity_rank(result)]&.to_s&.upcase || 'clean'
  end

  def self.result_lines(result, max_sites)
    lines = ['', "== #{result.name}  (sha256 #{result.sha256.to_s[0, 16]})"]
    lines << '  no findings' if result.findings.empty?
    groups = result.findings.group_by(&:category)
    groups.sort_by { |_, list| SEVERITIES.index(list.first.severity) }.each do |category, list|
      lines << "  #{category}  #{list.first.severity.to_s.upcase}  (#{list.size})"
      list.first(max_sites).each { |finding| lines << "    #{site(finding)}" }
      lines << "    ... #{list.size - max_sites} more" if list.size > max_sites
    end
    result.notes.each { |note| lines << "  note: #{note}" }
    lines << resource_line(result.resources) if result.resources.any?
    lines
  end

  def self.resource_line(resources)
    "  embedded resources: #{resources.size} (#{resources.first(5).join(', ')})"
  end

  def self.site(finding)
    return "#{finding.file}: #{finding.text}" if finding.line.zero?

    "#{finding.file}:#{finding.line}: #{finding.text[0, 140]}"
  end

  def self.audit_dll(dll, root, decompiler, out_dir)
    bytes = File.binread(dll)
    name = dll.delete_prefix("#{root}/")
    findings = Binary.findings(Binary.report(bytes), name)
    resources = []
    if findings.none? { |finding| finding.category == :native_dll }
      target = File.join(out_dir, name.tr('/', '_'))
      FileUtils.mkdir_p(target)
      decompiler.call(dll, target)
      findings += scan_tree(target)
      resources = decompiler.resources(dll)
    end
    Result.new(name: name, sha256: Digest::SHA256.hexdigest(bytes), findings: findings,
               notes: [], resources: resources)
  end

  def self.scan_tree(dir)
    Dir.glob('**/*.cs', base: dir).sort.flat_map do |relative|
      scan_source(relative, File.read(File.join(dir, relative), mode: 'r:UTF-8').scrub)
    end
  end

  def self.layout_result(path)
    findings = Layout.problems(path).map do |problem|
      severity = problem.match?(/executable|symlink/) ? :high : :medium
      Finding.new(:layout, severity, path, 0, problem)
    end
    Result.new(name: "#{path} (files)", sha256: nil, findings: findings, notes: [], resources: [])
  end

  def self.audit_path(path, decompiler, options)
    root = File.directory?(path) ? path : File.dirname(path)
    dlls = discover(path, skip_known: options[:skip_known]).map do |dll|
      audit_dll(dll, root, decompiler, options[:out])
    end
    File.directory?(path) ? [layout_result(path)] + dlls : dlls
  end

  def self.option_parser(options)
    OptionParser.new do |parser|
      parser.banner = 'Usage: audit.rb [options] PATH...   (PATH is a mod folder or a .dll)'
      parser.on('--skip-known', 'skip framework, Unity and Harmony DLLs by name') do
        options[:skip_known] = true
      end
      parser.on('--out DIR', 'where decompiled C# goes (default unity-audit-out)') do |dir|
        options[:out] = dir
      end
      parser.on('--max-sites N', Integer, 'locations shown per finding (default 5)') do |count|
        options[:max_sites] = count
      end
    end
  end

  def self.run(argv, out: $stdout)
    options = { skip_known: false, out: 'unity-audit-out', max_sites: 5 }
    parser = option_parser(options)
    paths = parser.parse(argv)
    abort parser.help if paths.empty?

    decompiler = Decompiler.new(tool: Decompiler.locate)
    results = paths.flat_map { |path| audit_path(path, decompiler, options) }
    out.puts format_report(results, max_sites: options[:max_sites])
    out.puts "\nDecompiled C# is in #{File.expand_path(options[:out])}"
  end
end

UnityModAudit.run(ARGV) if $PROGRAM_NAME == __FILE__

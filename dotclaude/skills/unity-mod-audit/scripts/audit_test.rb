#!/usr/bin/env ruby
# frozen_string_literal: true

# ruby audit_test.rb
# rubocop:disable Style/OneClassPerFile
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative 'audit'

class ScanSourceTest < Minitest::Test
  def scan(code)
    UnityModAudit.scan_source('Mod.cs', code)
  end

  def categories(code)
    scan(code).map { |f| [f.category, f.severity] }
  end

  def test_network_client_is_high
    assert_equal [%i[network high]], categories('var c = new WebClient();')
  end

  def test_unity_web_request_is_network
    assert_equal [%i[network high]], categories('UnityWebRequest.Get(url);')
  end

  def test_open_url_is_a_medium_link
    assert_equal [%i[links medium]], categories('Application.OpenURL("https://example.com");')
  end

  def test_process_start_is_high
    assert_equal [%i[process high]], categories('Process.Start("calc");')
  end

  def test_dll_import_is_native
    assert_equal [%i[native high]], categories('[DllImport("kernel32.dll")]')
  end

  def test_assembly_load_is_dynamic_code
    assert_equal [%i[dynamic_code high]], categories('var a = Assembly.Load(bytes);')
  end

  def test_a_using_directive_alone_is_not_a_finding
    assert_empty scan("using System.Reflection.Emit;\nusing System.Net.Http;")
  end

  def test_aliased_and_static_using_directives_are_not_findings
    assert_empty scan("using Http = System.Net.Http;\nglobal using static System.Net.WebClient;")
  end

  def test_a_using_statement_that_opens_a_resource_is_still_scanned
    assert_equal [%i[network high]], categories('using var client = new WebClient();')
  end

  def test_building_a_dynamic_method_is_dynamic_code
    assert_equal [%i[dynamic_code high]], categories('var m = new DynamicMethod("x", t, a);')
  end

  def test_harmony_il_patching_is_a_low_finding
    assert_equal [%i[il_patching low]], categories('list.Add(new CodeInstruction(OpCodes.Nop));')
  end

  def test_file_read_is_medium
    assert_equal [%i[files medium]], categories('var t = File.ReadAllText(path);')
  end

  def test_environment_lookup_is_medium
    assert_equal [%i[environment medium]], categories('Environment.GetEnvironmentVariable("HOME");')
  end

  def test_base64_decode_is_an_encoding_finding
    assert_equal [%i[encoding medium]], categories('var b = Convert.FromBase64String(s);')
  end

  def test_secret_words_count_only_inside_string_literals
    assert_equal [%i[secrets high]], categories('var p = "C:\\\\Users\\\\x\\\\.ssh\\\\id_rsa";')
    assert_empty categories('var passwordField = GetPasswordField();')
  end

  def test_secret_words_match_in_any_case
    assert_equal [%i[secrets high]], categories('var k = "LOGIN DATA";')
  end

  def test_a_string_that_merely_mentions_an_api_is_not_a_call
    assert_empty scan('var note = "do not call Process.Start or new WebClient()";')
  end

  def test_thread_creation_is_low
    assert_equal [%i[threads low]], categories('new Thread(Run).Start();')
  end

  def test_reports_the_one_based_line_and_the_trimmed_text
    finding = scan("class A {\n    void F() {\n        Process.Start(x);\n    }\n}").first

    assert_equal [3, 'Process.Start(x);'], [finding.line, finding.text]
  end

  def test_ignores_line_comments
    assert_empty scan('// Process.Start("calc");')
  end

  def test_ignores_block_comment_lines
    assert_empty scan("/*\n new WebClient();\n*/")
  end

  def test_clean_unity_code_has_no_findings
    code = 'void Update() { Debug.Log("hi"); Instantiate(prefab); transform.Translate(v); }'

    assert_empty scan(code)
  end

  def test_one_line_can_hit_two_categories
    assert_equal %i[network process],
                 scan('new WebClient(); Process.Start(x);').map(&:category).sort
  end

  def test_a_line_comment_does_not_hide_the_next_line
    assert_equal [2], scan("// harmless\nProcess.Start(x);").map(&:line)
  end

  def test_code_before_a_trailing_comment_is_still_scanned
    assert_equal [%i[process high]], categories('Process.Start(x); // launches it')
  end

  def test_slashes_inside_a_string_do_not_start_a_comment
    found = scan('Application.OpenURL("http://a"); Process.Start(x);')

    assert_equal %i[links process], found.map(&:category).sort
  end

  def test_code_after_a_closed_block_comment_on_the_same_line_is_scanned
    assert_equal [%i[process high]], categories('/* note */ Process.Start(x);')
  end
end

class BinaryTest < Minitest::Test
  def fake_pe(sections, tail = '')
    header = "MZ#{"\0" * 0x3a}#{[0x80].pack('V')}".b.ljust(0x80, "\0")
    header << "PE\0\0".b << [0x14c, sections.size, 0, 0, 0, 0, 0].pack('vvVVVvv')
    sections.each do |name|
      header << name.b.ljust(8, "\0") << [0, 0, 100].pack('VVV').ljust(32, "\0")
    end
    header + tail.b
  end

  def test_random_data_is_high_entropy
    report = UnityModAudit::Binary.report(Random.new(1).bytes(8192))

    assert_equal 2, report.high_blocks
  end

  def test_plain_text_is_not_high_entropy
    assert_equal 0, UnityModAudit::Binary.report(('code ' * 2000).b).high_blocks
  end

  def test_managed_assemblies_carry_the_metadata_signature
    assert UnityModAudit::Binary.report(fake_pe(['.text'], 'BSJB')).managed
  end

  def test_pe_without_metadata_is_not_managed
    refute UnityModAudit::Binary.report(fake_pe(['.text'], 'nothing')).managed
  end

  def test_section_names_are_read_from_the_pe_header
    report = UnityModAudit::Binary.report(fake_pe(['.text', 'UPX1']))

    assert_equal ['.text', 'UPX1'], report.sections
  end

  def test_unusual_section_names_are_flagged
    assert_equal ['UPX1'], UnityModAudit::Binary.report(fake_pe(['.text', 'UPX1'])).odd_sections
  end

  def test_standard_section_names_are_not_flagged
    assert_empty UnityModAudit::Binary.report(fake_pe(['.text', '.rsrc', '.reloc'])).odd_sections
  end

  def test_an_embedded_pe_file_is_found
    embedded = UnityModAudit::Binary.report(fake_pe(['.text'], "xx#{fake_pe(['.text'])}")).embedded

    assert_equal ['pe'], embedded
  end

  def test_a_stray_mz_without_a_pe_header_is_not_an_embedded_exe
    stray = fake_pe(['.text'], "xxMZ#{"\0" * 80}xx")

    assert_empty UnityModAudit::Binary.report(stray).embedded
  end

  def test_embedded_zip_and_gzip_are_found
    embedded = UnityModAudit::Binary.report(fake_pe(['.text'],
                                                    "a PK\x03\x04 b \x1f\x8b\x08 c")).embedded

    assert_equal %w[zip gzip], embedded
  end

  def test_garbage_input_does_not_raise
    report = UnityModAudit::Binary.report('not a pe file'.b)

    assert_equal [], report.sections
  end
end

class LayoutTest < Minitest::Test
  PNG = "\x89PNG\r\n\x1a\n#{"\0" * 8}".b

  def problems(files)
    Dir.mktmpdir do |dir|
      files.each do |name, content|
        path = File.join(dir, name)
        FileUtils.mkdir_p(File.dirname(path))
        File.binwrite(path, content)
      end
      yield dir if block_given?
      UnityModAudit::Layout.problems(dir).map { |p| p.sub("#{dir}/", '') }
    end
  end

  def test_a_clean_mod_has_no_problems
    assert_empty problems('a.png' => PNG, 'a.dll' => "MZ\0\0", 'manifest.xml' => '<x/>')
  end

  def test_an_executable_hiding_behind_another_extension_is_flagged
    assert_equal ['loot.png: executable (pe)'], problems('loot.png' => "MZ#{"\0" * 20}")
  end

  def test_an_elf_binary_is_flagged
    assert_equal ['run.txt: executable (elf)'], problems('run.txt' => "\x7fELF\x02\x01")
  end

  def test_a_script_with_a_shebang_is_flagged
    assert_equal ['go.csv: executable (script)'], problems('go.csv' => "#!/bin/sh\nrm -rf /\n")
  end

  def test_an_image_that_is_not_an_image_is_flagged
    assert_equal ['a.png: not a real png'], problems('a.png' => 'hello')
  end

  def test_dlls_are_allowed_to_be_executable_code
    assert_empty problems('mod.dll' => "MZ#{"\0" * 20}")
  end

  def test_hidden_files_are_flagged
    assert_equal ['.secret: hidden file'], problems('.secret' => 'x')
  end

  def test_symlinks_are_flagged
    result = problems('a.png' => PNG) { |dir| File.symlink('/etc/hosts', File.join(dir, 'link')) }

    assert_equal ['link: symlink'], result
  end
end

class DiscoverTest < Minitest::Test
  def discover(names, skip_known: false, target: nil)
    Dir.mktmpdir do |dir|
      names.each do |name|
        FileUtils.mkdir_p(File.dirname(File.join(dir, name)))
        File.write(File.join(dir, name), 'x')
      end
      found = UnityModAudit.discover(target ? File.join(dir, target) : dir, skip_known: skip_known)
      found.map { |p| p.sub("#{dir}/", '') }
    end
  end

  def test_finds_dlls_recursively_in_a_folder
    assert_equal ['a/Mod.dll', 'b/Other.dll'], discover(['a/Mod.dll', 'b/Other.dll', 'a/x.png'])
  end

  def test_scans_framework_named_dlls_by_default_because_a_mod_could_hide_behind_the_name
    assert_equal ['a/Mod.dll', 'a/System.Core.dll'], discover(['a/Mod.dll', 'a/System.Core.dll'])
  end

  def test_skip_known_drops_framework_and_unity_assemblies
    names = ['a/Mod.dll', 'a/System.Core.dll', 'a/UnityEngine.CoreModule.dll',
             'a/Assembly-CSharp.dll', 'a/0Harmony.dll', 'a/Newtonsoft.Json.dll', 'a/mscorlib.dll',
             'a/Unity.TextMeshPro.dll']

    assert_equal ['a/Mod.dll'], discover(names, skip_known: true)
  end

  def test_skip_known_keeps_mods_that_only_start_with_a_framework_word
    assert_equal ['a/SystemTweaks.dll', 'a/UnityHelper.dll'],
                 discover(['a/SystemTweaks.dll', 'a/UnityHelper.dll'], skip_known: true)
  end

  def test_a_single_dll_path_is_returned_even_if_skip_known_would_drop_it
    assert_equal ['a/System.dll'],
                 discover(['a/System.dll'], skip_known: true, target: 'a/System.dll')
  end
end

class DecompilerTest < Minitest::Test
  Status = Struct.new(:success) do
    def success? = success
  end

  def test_runs_ilspycmd_in_project_mode_into_the_output_dir
    calls = []
    runner = lambda do |*cmd|
      calls << cmd
      ['', '', Status.new(true)]
    end
    UnityModAudit::Decompiler.new(tool: '/bin/ilspycmd', runner: runner).call('/m/A.dll', '/out/A')

    assert_equal [['/bin/ilspycmd', '-p', '-o', '/out/A', '/m/A.dll']], calls
  end

  def test_a_failing_run_raises_with_the_tools_message
    runner = ->(*) { ['', 'bad assembly', Status.new(false)] }
    error = assert_raises(UnityModAudit::Error) do
      UnityModAudit::Decompiler.new(tool: 'x', runner: runner).call('/m/A.dll', '/out')
    end

    assert_match(/bad assembly/, error.message)
  end

  def test_lists_resources_one_per_line
    runner = ->(*) { ["a.png\nb/c.json\n", '', Status.new(true)] }

    assert_equal ['a.png', 'b/c.json'],
                 UnityModAudit::Decompiler.new(tool: 'x', runner: runner).resources('/m/A.dll')
  end

  def test_a_missing_tool_explains_how_to_install_it
    error = assert_raises(UnityModAudit::Error) { UnityModAudit::Decompiler.locate(path: [], home: '/nonexistent') }

    assert_match(/dotnet tool install -g ilspycmd/, error.message)
  end
end

class BinaryFindingsTest < Minitest::Test
  Report = UnityModAudit::BinaryReport

  def findings(report)
    UnityModAudit::Binary.findings(report, 'Mod.dll').map { |f| [f.category, f.severity, f.text] }
  end

  def test_a_clean_managed_dll_has_no_findings
    assert_empty findings(Report.new(true, 10, 0, ['.text'], [], []))
  end

  def test_a_native_dll_is_flagged_high
    result = findings(Report.new(false, 10, 0, ['.text'], [], []))

    assert_equal [[:native_dll, :high, 'not a .NET assembly (native code or not a DLL)']], result
  end

  def test_high_entropy_blocks_say_how_many
    result = findings(Report.new(true, 10, 3, ['.text'], [], []))

    assert_equal [[:packed, :high, '3/10 blocks above 7.2 bits per byte']], result
  end

  def test_each_unusual_section_is_flagged
    result = findings(Report.new(true, 10, 0, ['.text', 'UPX0', 'UPX1'], %w[UPX0 UPX1], []))

    assert_equal ['unusual PE section UPX0', 'unusual PE section UPX1'], result.map(&:last)
  end

  def test_embedded_files_are_flagged
    result = findings(Report.new(true, 10, 0, ['.text'], [], %w[pe zip]))

    assert_equal [[:embedded, :high, 'embedded pe data'], [:embedded, :high, 'embedded zip data']],
                 result
  end
end

class AuditDllTest < Minitest::Test
  # Stands in for ilspycmd: writes a C# file instead of decompiling anything.
  class FakeDecompiler
    attr_reader :calls

    def initialize(source)
      @source = source
      @calls = []
    end

    def call(dll, out_dir)
      @calls << dll
      File.write(File.join(out_dir, 'Mod.cs'), @source)
    end

    def resources(_dll) = ['icon.png']
  end

  MANAGED = "MZ#{"\0" * 0x3a}#{[0x80].pack('V')}".b.ljust(0x80, "\0") +
            "PE\0\0".b + [0x14c, 1, 0, 0, 0, 0, 0].pack('vvVVVvv') +
            '.text'.b.ljust(8, "\0") + ("\0" * 32) + 'BSJB'.b

  def audit(bytes, source: "void F() {\n  Process.Start(x);\n}")
    Dir.mktmpdir do |dir|
      File.binwrite(File.join(dir, 'Mod.dll'), bytes)
      decompiler = FakeDecompiler.new(source)
      result = UnityModAudit.audit_dll(File.join(dir, 'Mod.dll'), dir, decompiler,
                                       File.join(dir, 'out'))
      yield result, decompiler
    end
  end

  def test_decompiled_code_is_scanned_and_located
    audit(MANAGED) do |result, _|
      sites = result.findings.map { |f| [f.file, f.line, f.category] }

      assert_equal [['Mod.cs', 2, :process]], sites
    end
  end

  def test_resources_and_hash_are_reported
    audit(MANAGED) do |result, _|
      expected = [['icon.png'], Digest::SHA256.hexdigest(MANAGED)]

      assert_equal expected, [result.resources, result.sha256]
    end
  end

  def test_a_native_dll_is_never_sent_to_the_decompiler
    audit('MZ native'.b) do |result, decompiler|
      assert_equal [[], [:native_dll]], [decompiler.calls, result.findings.map(&:category)]
    end
  end

  def test_the_name_is_relative_to_the_root
    audit(MANAGED) { |result, _| assert_equal 'Mod.dll', result.name }
  end
end

class LayoutResultTest < Minitest::Test
  def severities(files)
    Dir.mktmpdir do |dir|
      files.each { |name, content| File.binwrite(File.join(dir, name), content) }
      UnityModAudit.layout_result(dir).findings.map { |f| [f.text.sub(/\A.*?: /, ''), f.severity] }
    end
  end

  def test_executables_are_high_and_hidden_files_are_medium
    result = severities('loot.png' => 'MZ.....', '.hidden' => 'x')

    assert_equal [['hidden file', :medium], ['executable (pe)', :high]], result
  end
end

class ReportTest < Minitest::Test
  Finding = UnityModAudit::Finding

  def result(name, findings, odd: [])
    UnityModAudit::Result.new(name: name, sha256: 'ab' * 32, findings: findings, notes: odd,
                              resources: [])
  end

  def test_lists_each_dll_with_its_findings_and_location
    finding = Finding.new(:network, :high, 'Mod/Net.cs', 7, 'new WebClient();')
    text = UnityModAudit.format_report([result('Mod.dll', [finding])], max_sites: 5)

    assert_match(%r{Mod\.dll.*\n.*network.*HIGH.*\n\s+Mod/Net\.cs:7: new WebClient\(\);}i, text)
  end

  def test_caps_the_sites_shown_per_category_and_says_how_many_were_hidden
    findings = Array.new(4) { |i| Finding.new(:files, :medium, 'A.cs', i + 1, 'File.Delete(x);') }
    text = UnityModAudit.format_report([result('Mod.dll', findings)], max_sites: 2)

    assert_equal [2, true], [text.scan('A.cs:').size, text.include?('2 more')]
  end

  def test_a_clean_dll_says_nothing_was_found
    assert_match(/Mod\.dll.*\n.*no findings/i,
                 UnityModAudit.format_report([result('Mod.dll', [])], max_sites: 5))
  end

  def test_binary_findings_without_a_line_print_just_the_file_and_text
    finding = Finding.new(:packed, :high, 'Mod.dll', 0, 'unusual PE section UPX1')
    text = UnityModAudit.format_report([result('Mod.dll', [finding])], max_sites: 5)

    assert_includes text, "\n    Mod.dll: unusual PE section UPX1"
  end

  def test_resources_are_listed_when_present
    res = UnityModAudit::Result.new(name: 'Mod.dll', sha256: 'ab', findings: [], notes: [],
                                    resources: %w[a.png b.json])

    text = UnityModAudit.format_report([res], max_sites: 5)

    assert_includes text, 'embedded resources: 2 (a.png, b.json)'
  end

  def test_summary_orders_dlls_by_worst_severity
    clean = result('Clean.dll', [])
    bad = result('Bad.dll', [Finding.new(:process, :high, 'A.cs', 1, 'Process.Start(x);')])
    text = UnityModAudit.format_report([clean, bad], max_sites: 5)

    assert_operator text.index('Bad.dll  HIGH'), :<, text.index('Clean.dll  clean')
  end
end

# rubocop:enable Style/OneClassPerFile

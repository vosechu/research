# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A MATLAB tutoring agent for introductory coursework. Two key files:

- `matlab-reference.md` — Dense reference compiled from MathWorks docs (keywords, functions, errors, patterns, gotchas)
- `.claude/agents/matlab-tutor.md` — Agent definition with pedagogical rules

## Usage

Invoke the tutor agent from Claude Code. The agent reads `matlab-reference.md` for grounded answers.

## Editing the Reference

When updating `matlab-reference.md`, keep entries focused on what introductory students encounter. Each function entry needs: name, signature, one-line description. Error entries need: message, meaning, typical cause, fix.

## Agent Behavior

The agent classifies questions as homework (guide, don't give answers), utility (provide directly), or debugging (always help fully). If modifying the agent, preserve this three-category classification.

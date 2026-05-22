#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "yaml"

ROOT = File.expand_path("..", __dir__)
POSTS = File.join(ROOT, "_posts")

groups = Hash.new { |h, k| h[k] = [] }

Dir.glob(File.join(POSTS, "*.md")).sort.each do |path|
  content = File.read(path)
  next unless content.start_with?("---\n")

  parts = content.split("---\n", 3)
  front = YAML.safe_load(parts[1], permitted_classes: [Date, Time])
  key = front["translation_key"]
  next unless key.is_a?(String) && !key.empty?

  groups[key] << { path: File.basename(path), lang: front["lang"] }
end

warnings = 0
groups.each do |key, entries|
  if entries.size != 2
    warn "translation_key=#{key}: expected 2 posts, found #{entries.size} (#{entries.map { |e| e[:path] }.join(', ')})"
    warnings += 1
  end

  langs = entries.map { |e| e[:lang] }.compact
  %w[en pt].each do |expected|
    next if langs.include?(expected)

    warn "translation_key=#{key}: missing lang=#{expected}"
    warnings += 1
  end
end

if warnings.zero?
  puts "OK: #{groups.size} translation_key groups, all valid pairs"
else
  warn "#{warnings} warning(s) in #{groups.size} translation_key group(s)"
  exit 1
end

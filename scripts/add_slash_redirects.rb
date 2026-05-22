#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "yaml"

ROOT = File.expand_path("..", __dir__)
POSTS = File.join(ROOT, "_posts")

Dir.glob(File.join(POSTS, "*.md")).sort.each do |path|
  content = File.read(path)
  next unless content.start_with?("---\n")

  parts = content.split("---\n", 3)
  front = YAML.safe_load(parts[1], permitted_classes: [Date, Time])
  permalink = front["permalink"]
  next unless permalink.is_a?(String) && permalink.end_with?("/")

  slug = front["slug"] || File.basename(path, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
  resolved = permalink.gsub(":slug", slug)
  slashless = resolved.sub(%r{/\z}, "")
  redirects = Array(front["redirect_from"]).map(&:to_s)
  candidates = [slashless, "#{slashless}/"]
  changed = false
  candidates.each do |candidate|
    next if redirects.include?(candidate)
    redirects << candidate
    changed = true
  end
  next unless changed

  front["redirect_from"] = redirects.uniq
  new_front = front.to_yaml.sub(/\A---\n/, "").strip
  File.write(path, "---\n#{new_front}\n---\n#{parts[2]}")
  puts "updated #{File.basename(path)}"
end

module EasyDiff
  module Core
    def self.easy_diff(original, modified)
      removed = nil
      added   = nil

      if original.nil?
        added = modified.safe_dup
      elsif modified.nil?
        removed = original.safe_dup
      elsif original.is_a?(Hash) && modified.is_a?(Hash)
        removed = {}
        added   = {}
        original_keys   = original.keys
        modified_keys   = modified.keys
        keys_in_common  = original_keys & modified_keys
        keys_removed    = original_keys - modified_keys
        keys_added      = modified_keys - original_keys
        keys_removed.each{ |key| removed[key] = original[key].safe_dup }
        keys_added.each{ |key| added[key] = modified[key].safe_dup }
        keys_in_common.each do |key|
          r, a = easy_diff original[key], modified[key]
          removed[key] = r unless r.nil? || ((r.is_a?(Hash) || r.is_a?(Array)) && r.empty?)
          added[key] = a unless a.nil? || ((a.is_a?(Hash) || a.is_a?(Array)) && a.empty?)
        end
      elsif original.is_a?(Array) && modified.is_a?(Array)
        removed = original - modified
        added   = modified - original
        removed.each_with_index do |val, index|
          #WARN: arrays must be ordered the same way.
          #TODO: order hash elements in some way
          if removed[index].is_a?(Hash)
            r, a = easy_diff removed[index], added[index]
            removed[index] = r unless r.nil? || r.empty?
            added[index] = a unless a.nil? || a.empty?
          end
        end
      elsif original != modified
        removed   = original
        added     = modified
      end
      return removed, added
    end

    def self.easy_unmerge!(original, removed)
      if original.is_a?(Hash) && removed.is_a?(Hash)
        original_keys  = original.keys
        removed_keys   = removed.keys
        keys_in_common = original_keys & removed_keys
        keys_in_common.each{ |key| original.delete(key) if easy_unmerge!(original[key], removed[key]).nil? }
      elsif original.is_a?(Array) && removed.is_a?(Array)
        original.reject!{ |e| removed.include?(e) }
        original.sort!
      elsif original == removed
        original = nil
      end
      original
    end

    def self.easy_merge!(original, added)
      if added.nil?
        return original
      elsif original.is_a?(Hash) && added.is_a?(Hash)
        added_keys = added.keys
        added_keys.each{ |key| original[key] = easy_merge!(original[key], added[key])}
      elsif original.is_a?(Array) && added.is_a?(Array)
        original |=  added
        original.sort!
      else
        original = added.safe_dup
      end
      original
    end

    def self.easy_clone(original)
      Marshal::load(Marshal.dump(original))
    end
  end
end
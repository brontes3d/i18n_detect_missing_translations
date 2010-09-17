class I18nMissingTranslations
  
  class MissingTranslation
    attr_reader :locale, :key, :found_in_locale
    def initialize(locale, key, found_in_locale)
      @locale = locale
      @key = key
      @found_in_locale = found_in_locale
    end
    def to_s
      "#{@locale} missing #{@key} (found in #{@found_in_locale})"
    end
  end
  
  def self.found_in_files_scan_but_missing_from_en
    to_return = []
    lookup_pattern = Translate::Keys.new.send(:i18n_lookup_pattern)
    Dir.glob(File.join(RAILS_ROOT,"app", "**","*.{rb,rhtml,erb}")).each do |file_name|
      File.open(file_name, "r+").each do |line|
        pattern = /\b([a-zA-Z]+)\.(human_attribute_name|han)\(["']{1}([a-z0-9_]+)["']{1}\)/
        line.scan(pattern) do |key_string|
          model = key_string[0].underscore
          att_key = key_string[2]
          composed_key = "activerecord.attributes.#{model}.#{att_key}"
          unless I18n.backend.send(:lookup, "en", composed_key)
            to_return << MissingTranslation.new("en", composed_key, file_name + ": " + key_string.join(" "))
          end
        end
        line.scan(lookup_pattern) do |key_string|
          unless I18n.backend.send(:lookup, "en", key_string)
            to_return << MissingTranslation.new("en", key_string, file_name)
          end
        end
      end
    end
    to_return
  end
  
  def self.missing_from_other_locales(other_locales = (PERMITTED_LOCALES.keys - ["en"]))
    english_keys = Translate::Keys.new.i18n_keys("en")
    to_return = []
    other_locales.each do |locale|
      locale_keys = Translate::Keys.new.i18n_keys(locale)
      english_keys.each do |e_key|
        unless locale_keys.include?(e_key)
          unless I18n.backend.send(:lookup, locale, e_key)
            to_return << MissingTranslation.new(locale, e_key, "en")
          end
        end
      end
    end
    to_return
  end
  
  def self.missing_from_en
    english_keys = Translate::Keys.new.i18n_keys("en")
    to_return = []
    (PERMITTED_LOCALES.keys - ["en"]).each do |locale|
      locale_keys = Translate::Keys.new.i18n_keys(locale)
      locale_keys.each do |locale_key|
        unless english_keys.include?(locale_key)
          unless I18n.backend.send(:lookup, "en", locale_key)
            to_return << MissingTranslation.new("en", locale_key, locale)
          end
        end
      end
    end
    to_return
  end
  
end
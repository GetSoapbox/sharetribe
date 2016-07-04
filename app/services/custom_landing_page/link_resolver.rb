module CustomLandingPage
  module LinkResolver

    class LinkResolvingError < StandardError; end

    class PathResolver
      def initialize(paths)
        @_paths = paths
      end

      def call(type, id, _)
        path = @_paths[id]

        if path.nil?
          raise LinkResolvingError.new("Couldn't find path '#{id}'.")
        else
          { "id" => id, "type" => type, "value" => path }
        end
      end
    end

    class MarketplaceDataResolver
      def initialize(data)
        @_data = data
      end

      def call(type, id, _)
        unless @_data.key?(id)
          raise LinkResolvingError.new("Unknown marketplace data value '#{id}'.")
        end

        value = @_data[id]
        { "id" => id, "type" => type, "value" => value }
      end
    end

    class AssetResolver
      def initialize(asset_host, sitename)
        unless sitename.present?
          raise CustomLandingPage::LandingPageConfigurationError.new("Missing sitename.")
        end

        @_asset_host = asset_host
        @_sitename = sitename
      end

      def call(type, id, normalized_data)
        asset = normalized_data[type].find { |item| item["id"] == id }

        if asset.nil?
          raise LinkResolvingError.new("Unable to find an asset with id '#{id}'.")
        else
          append_asset_path(asset)
        end
      end


      private

      def append_asset_path(asset)
        if @_asset_host.present?
          asset.merge("src" => [@_asset_host, @_sitename, asset["src"]].join("/"))
        else
          # If asset_host is not configured serve assets locally
          asset.merge("src" => ["landing_page", asset["src"]].join("/"))
        end
      end
    end

    class TranslationResolver
      def initialize(locale)
        @_locale = locale
      end

      def call(type, id, _)
        translation_keys = {
          "search_button" => "landing_page.hero.search",
          "signup_button" => "landing_page.hero.signup",
          "no_listing_image" => "landing_page.listings.no_listing_image"
        }

        key = translation_keys[id]

        raise LinkResolvingError.new("Couldn't find translation key for '#{id}'.") if key.nil?

        value = I18n.translate(key, locale: @_locale)

        if value.nil?
          raise LinkResolvingError.new("Unknown translation for key '#{key}' and locale '#{locale}'.")
        else
          { "id" => id, "type" => type, "value" => value }
        end
      end
    end

    class CategoryResolver
      def initialize(data)
        @_data = data
      end

      def call(type, id, _)
        unless @_data.key?(id)
          raise LinkResolvingError.new("Unknown category id '#{id}'.")
        end

        @_data[id].merge("id" => id, "type" => type)
      end
    end

    class ListingResolver
      def initialize(cid, locale, name_display_type)
        @_cid = cid
        @_locale = locale
        @_name_display_type = name_display_type
      end

      def call(type, id, _)
        ListingStore.listing(id: id,
                             community_id: @_cid,
                             locale: @_locale,
                             name_display_type: @_name_display_type)
      end

    end

    class RequestResolver
      def initialize(request)
        @_request = request
      end

      def call(type, id, _)
        data =
          case id
          when "host_with_port_and_protocol"
            { "value" => "#{@_request.protocol}#{@_request.host_with_port}"}
          else
            raise LinkResolvingError.new("Unknown request id '#{id}'.")
          end

        data.merge("id" => id, "type" => type)
      end
    end
  end
end

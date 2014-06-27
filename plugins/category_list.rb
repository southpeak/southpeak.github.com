# encoding: utf-8
module Jekyll

  class Site

    def create_category_list
      write_to_tag_cloud if @config['category_tag_cloud']
      write_to_sidebar if @config['category_sidebar']
    end

    private
    # generate category tag list and write to 'source/_includes/asides/categories_tag.html'
    def write_to_tag_cloud
      puts ' => Creating Categories Tag Cloud'
      lists = {}
      max, min = 1, 1
      self.categories.keys.sort_by{ |str| str.downcase }.each do |category|
        count = self.categories[category].count
        lists[category] = count
        max = count if count > max
      end

      html = ''
      lists.each do | category, counter |
        url = get_category_url category
        style = "font-size: #{100 + (60 * Float(counter)/max)}%"
        if @config['category_counter']
          html << " <a href='#{url}' style='#{style}'>#{category}(#{self.categories[category].count})</a> "
        else
          html << " <a href='#{url}' style='#{style}'>#{category}</a> "
        end
      end
      File.open(File.join(@source, '_includes/asides/categories_tag.html'), 'w') do |file|
        file << """{% if site.category_tag_cloud %}
<section>
<h1>#{self.config['category_title'] || 'Categories'}</h1>
<span class='categories_tag'>#{html}</span>
</section>
{% endif %}
"""
      end
    end

    # generate category lists and write to 'source/_includes/asides/categories_sidebar.html'
    def write_to_sidebar
      puts ' => Creating Categories Sidebar'
      html = "<ul>\n"
      # case insensitive sorting
      self.categories.keys.sort_by{ |str| str.downcase }.each do |category|
        url = get_category_url category
        if self.config['category_counter']
          html << "  <li><a href='#{url}'>#{category} (#{self.categories[category].count})</a></li>\n"
        else
          html << "  <li><a href='#{url}'>#{category}</a></li>\n"
        end
      end
      html << "</ul>"
      File.open(File.join(@source, '_includes/asides/categories_sidebar.html'), 'w') do |file|
        file << """{% if site.category_sidebar %}
<section>
<h1>#{self.config['category_title'] || 'Categories'}</h1>
#{html}
</section>
{% endif %}
"""
      end
    end

    def get_category_url(category)
      dir = self.config['category_dir'] || 'categories'
      File.join @config['root'], dir, category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase
    end
  end

  class CategoryList < Generator
    safe true
    priority :low

    def generate(site)
      if site.config['category_list']
        puts "## Generating Categories.."
        site.create_category_list
      end
    end
  end

end

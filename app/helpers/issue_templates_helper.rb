module IssueTemplatesHelper

  def project_tree_options(projects, options = {})
    s = ''
    project_tree(projects) do |project, level|
      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => project.id}
      if project == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(project))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      if options[:disabled].respond_to?(:include?) && options[:disabled].include?(project)
        tag_options[:disabled] = 'disabled'
      else
        tag_options[:disabled] = nil
      end
      tag_options.merge!(yield(project)) if block_given?
      s << content_tag('option', name_prefix + h(project), tag_options)
    end
    s.html_safe
  end

  def reorder_templates_handle(object, options = {})
    data = {
        :reorder_url => options[:url] || url_for(object),
        :reorder_param => options[:param] || object.class.name.underscore
    }
    content_tag('span', '',
                :class => "icon-only icon-sort-handle sort-handle",
                :data => data)
  end

  def reload_current_value(sections_attributes, current_position)
    if sections_attributes.present?
      index = current_position - 1
      if @sections_attributes[index].present?
        return @sections_attributes[index]['text']
      end
    end
    return nil
  end

  def issue_template_section_form_path(section_class)
    "issue_templates/sections/#{section_class.name.underscore}_form"
  end

  def issue_template_section_form(&block)
    yield if block_given?
  end

end

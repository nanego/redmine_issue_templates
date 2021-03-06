require_dependency 'issues_controller'

class IssuesController < ApplicationController

  prepend_before_action :set_template_as_params, :only => [:new]
  append_before_action :finish_template_set_up, :only => [:new]

  append_before_action :keep_sections_values, :only => [:new, :create]
  append_before_action :update_description_with_sections, :only => [:create]

  def set_template_as_params
    if params[:template_id] && params[:template_id].to_i.to_s == params[:template_id]
      permitted_params_override = params[:issue].present? ? params.require(:issue).to_unsafe_h : {}
      @issue_template = IssueTemplate.find_by_id(params[:template_id])
      if @issue_template.present?
        params[:issue] = @issue_template.attributes.slice(*Issue.attribute_names).merge(permitted_params_override)
        params[:issue][:project_id] = params[:project_id]
      end
    end
  end

  def finish_template_set_up
    if @issue_template
      if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
        @issue.projects = @issue_template.secondary_projects
      end
      @issue.issue_template = @issue_template
      @issue_template.increment!(:usage)
    end
  end

  def set_template
    if params[:template_id] && params[:template_id].to_i.to_s == params[:template_id]
      permitted_params_override = params[:issue].present? ? params.require(:issue).to_unsafe_h : {}
      @issue_template = IssueTemplate.find_by_id(params[:template_id])
      if @issue_template.present?
        @issue.safe_attributes = @issue_template.attributes.slice(*Issue.attribute_names).merge(permitted_params_override)
        @issue.project = @project
        if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
          @issue.projects = @issue_template.secondary_projects
        end
        @issue.issue_template = @issue_template
        @issue_template.increment!(:usage)
      end
    end
  end

  def keep_sections_values
    if params[:issue].present? && params[:issue][:issue_template].present? && params[:issue][:issue_template][:descriptions_attributes].present?
      @sections_attributes = params[:issue][:issue_template][:descriptions_attributes].values
    end
  end

  def update_description_with_sections
    if @issue.issue_template&.split_description && params[:issue][:issue_template].present?
      description_text = ""
      descriptions_attributes = params[:issue][:issue_template][:descriptions_attributes].values
      descriptions_attributes.each_with_index do |description, i|
        section = @issue.issue_template.descriptions[i]
        case section.class.name
        when IssueTemplateDescriptionInstruction.name
          # Nothing to add
        when IssueTemplateDescriptionSeparator.name
          description_text += textile_separator
        when IssueTemplateDescriptionTitle.name
          description_text += textile_separator_with_title(section.title)
        when IssueTemplateDescriptionSelect.name
          case section.select_type
          when "monovalue_select", "radio"
            description_text += section_title(section.title, description[:text])
          else
            description_text += section_title(section.title)
            if section.text.present?
              if section.select_type == 'multivalue_select'
                selected_values = description['text'] || []
                selected_values.each do |selected_value|
                  description_text += textile_item(selected_value)
                end
              else
                section.text.split(';').each_with_index do |value, index|
                  boolean_value = description[index.to_s] == '1' ? l(:general_text_Yes) : l(:general_text_No)
                  description_text += textile_item(value, boolean_value)
                end
              end
            end
          end
        when IssueTemplateDescriptionCheckbox.name
          value = description[:text] == '1' ? l(:general_text_Yes) : l(:general_text_No)
          description_text += section_title(section.title, value)
        when IssueTemplateDescriptionField.name, IssueTemplateDescriptionDate.name
          value = description[:text].present? ? description[:text] : description[:empty_value]
          description_text += section_title(section.title, value)
        else
          description_text += section_title(section.title)
          value = description[:text].present? ? description[:text] : description[:empty_value]
          description_text += textile_entry(value)
        end
        @issue.description = description_text
      end
    end
  end

  def textile_separator_with_title(title)
    "#{textile_separator}\r\nh2. #{title}\r\n\r\n"
  end

  def section_title(title, value = nil)
    inline_value = value if value.present?
    "\r\n*#{title} :* #{inline_value}\r\n"
  end

  def textile_separator
    "\r\n-----\r\n"
  end

  def textile_item(label, inline_value = nil)
    inline_value = " : #{inline_value} " if inline_value.present?
    "* #{label}#{inline_value}\r\n"
  end

  def textile_entry(value)
    "#{value}\r\n"
  end
end

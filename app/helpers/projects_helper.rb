module ProjectsHelper
def project_filter_checbox(view, filter, count)
    name = "filter_by_project_#{view}"
    checked = (session[name] ? session[name].split(",").include?(filter.to_s) : count > 0)
    onclick = remote_function(
      :url      => { :action => :filter, :view => view },
      :with     => "'filter='+this.value+'&checked='+this.checked",
      :loading  => "$('loading').show()",
      :complete => "$('loading').hide()"
    )
    check_box_tag("filters[]", filter, checked, :onclick => onclick)
  end
end

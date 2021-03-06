class Ws::LabelsController < Ws::BaseController
  def create
    @label = Label.new event.data[:label].tap {|params| params.merge!(user_id: current_user.id, retrospective_id: @retrospective.id) }
    Label.transaction do
      @label.save!
      @label.insert_at 1
      trigger_channel 'labels.create', @label.as_json
    end
  rescue
    trigger_failure 'labels.create failed'
  end

  def destroy
    set_label
    @label.destroy
    trigger_channel 'labels.destroy', {id: @label.id}
  end

  def update
    set_label
    @label.update event.data[:label]
    trigger_channel 'labels.update', {id: @label.id, label: event.data[:label]}
  end

  def update_position
    set_label
    Label.transaction do
      if @label.typ != event.data[:typ]
        @label.remove_from_list
        @label.update! typ: event.data[:typ]
      end
      @label.insert_at event.data[:position].to_i
    end
    trigger_channel 'labels.update_position', {id: @label.id, typ: @label.typ, position: @label.position, label: @label.as_json}
  end

  def set_label
    @label = @retrospective.labels.where(id: event.data[:id]).first
    unless @label
      trigger_failure 'have not label'
      self.response_body = true
      return
    end
  end
end

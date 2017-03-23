ActiveAdmin.register Location do
  index do
    selectable_column
    id_column
    column :country
    column :address
    column :latitude
    column :longitude
    column :created_at
    actions
  end

  filter :id
  filter :country, as: :select, collection: proc { Location.pluck(:country).uniq.compact }
  filter :address
  filter :latitude
  filter :longitude
  filter :created_at
end

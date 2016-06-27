# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: analysis_items
#
#  absolute_measure_value_unit  :string
#  absolute_measure_value_value :decimal(19, 4)
#  analysis_id                  :integer          not null
#  annotation                   :text
#  boolean_value                :boolean          default(FALSE), not null
#  choice_value                 :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  decimal_value                :decimal(19, 4)
#  geometry_value               :geometry({:srid=>4326, :type=>"geometry"})
#  id                           :integer          not null, primary key
#  indicator_datatype           :string           not null
#  indicator_name               :string           not null
#  integer_value                :integer
#  lock_version                 :integer          default(0), not null
#  measure_value_unit           :string
#  measure_value_value          :decimal(19, 4)
#  multi_polygon_value          :geometry({:srid=>4326, :type=>"multi_polygon"})
#  point_value                  :geometry({:srid=>4326, :type=>"point"})
#  product_reading_id           :integer
#  string_value                 :text
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#

class AnalysisItem < Ekylibre::Record::Base
  include ReadingStorable
  belongs_to :analysis, inverse_of: :items
  belongs_to :product_reading, dependent: :destroy
  has_one :product, through: :analysis
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :integer_value, numericality: { allow_nil: true, only_integer: true }
  validates :absolute_measure_value_value, :decimal_value, :measure_value_value, numericality: { allow_nil: true }
  validates :boolean_value, inclusion: { in: [true, false] }
  validates :analysis, :indicator_datatype, :indicator_name, presence: true
  # ]VALIDATORS]
  validates :indicator_name, uniqueness: { scope: :analysis_id }

  delegate :sampled_at, to: :analysis

  after_save do
    if product
      if reading = product_reading
        reading.read_at = sampled_at
        reading.value = value
        reading.save!
      else
        reading = product.read!(indicator, value, at: sampled_at)
        update_column(:product_reading_id, reading.id)
      end
    end
  end
end

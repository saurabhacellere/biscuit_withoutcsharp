# frozen_string_literal: true

module ActiveJob
  module QueryTags # :nodoc:
    extend ActiveSupport::Concern

    included do
      around_perform :expose_job_to_query_logs
    end

    private
      def expose_job_to_query_logs(&block)
        ActiveRecord::QueryLogs.set_context(job: self, &block)
      end
  end
end

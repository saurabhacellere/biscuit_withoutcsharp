set termout off
create or replace package tst_empty_suite_path as
  --%suite
  --%suitepath

  --%test
  procedure test1;
end;
/

create or replace package body tst_empty_suite_path as
  procedure test1 is begin ut.expect(1).to_equal(1); end;
end;
/

set termout on

declare
  l_objects_to_run ut_suite_items;
  l_suite          ut_suite;
begin

  --act
  l_objects_to_run := ut_suite_manager.configure_execution_by_path(ut_varchar2_list('tst_empty_suite_path'));
  
  --Assert
  ut.expect(l_objects_to_run.count).to_equal(1);

  l_suite := treat(l_objects_to_run(1) as ut_suite);

  ut.expect(l_suite.name).to_equal('tst_empty_suite_path');

  if ut_expectation_processor.get_status = ut_utils.gc_success then
    :test_result := ut_utils.gc_success;
  end if;

end;
/

drop package tst_empty_suite_path
/

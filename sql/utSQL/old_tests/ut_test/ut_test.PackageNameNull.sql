PROMPT Reports error when unit test package name for a test is null

--Arrange
declare
	simple_test ut_test := ut_test(a_object_name => null, a_name => 'ut_passing_test');
begin
--Act
	simple_test.do_execute();
--Assert
	if simple_test.result = ut_utils.gc_error then
    :test_result := ut_utils.gc_success;
	else
		dbms_output.put_line('simple_test.result = '||ut_utils.test_result_to_char(simple_test.result));
	end if;
end;
/

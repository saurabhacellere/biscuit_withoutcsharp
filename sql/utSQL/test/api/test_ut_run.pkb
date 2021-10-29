create or replace package body test_ut_run is

  --%test(ut.version() returns version of the framework)
  procedure ut_version is
  begin
    ut.expect(ut3.ut.version()).to_match('^v\d+\.\d+\.\d+\.\d+(-\w+)?$');
  end;

  --%test(ut.fail() marks test as failed)
  procedure ut_fail is
  begin
    --Act
    ut3.ut.fail('Testing failure message');
    --Assert
    ut.expect(
        xmltype(anydata.convertCollection(ut3.ut_expectation_processor.get_failed_expectations())).getClobVal()
    ).to_be_like('%<STATUS>2</STATUS>%<MESSAGE>Testing failure message</MESSAGE>%');
    --Cleanup
    ut3.ut_expectation_processor.clear_expectations();
  end;


  function get_dbms_output_as_clob return clob is
    l_status number;
    l_line   varchar2(32767);
    l_result clob;
  begin

    dbms_output.get_line(line => l_line, status => l_status);
    if l_status != 1 then
      dbms_lob.createtemporary(l_result, true, dur => dbms_lob.session);
    end if;
    while l_status != 1 loop
      if l_line is not null then
        ut3.ut_utils.append_to_clob(l_result, l_line||chr(10));
      end if;
      dbms_output.get_line(line => l_line, status => l_status);
    end loop;
    return l_result;
  end;

  procedure create_ut3$user#_tests is
    pragma autonomous_transaction;
  begin
    execute immediate q'[create or replace package ut3$user#.test_package_1 is
      --%suite
      --%suitepath(tests)

      --%test(Test1 from test package 1)
      procedure test1;

      --%test(Test2 from test package 1)
      procedure test2;

      procedure run(a_reporter ut3.ut_reporter_base := null);
      procedure run(a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base);
      procedure run(a_path varchar2, a_reporter ut3.ut_reporter_base := null);
      procedure run(a_path varchar2, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base);
      procedure run(a_paths ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base := null);
      procedure run(a_paths ut3.ut_varchar2_list, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base);
      function run(a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list;
      function run(a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list;
      function run(a_path varchar2, a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list;
      function run(a_path varchar2, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list;
      function run(a_paths ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list;
      function run(a_paths ut3.ut_varchar2_list, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list;

    end test_package_1;
    ]';
    execute immediate q'[create or replace package body ut3$user#.test_package_1 is
      procedure test1 is
        begin
          dbms_output.put_line('test_package_1.test1 executed');
        end;
      procedure test2 is
        begin
          dbms_output.put_line('test_package_1.test2 executed');
        end;

      procedure run(a_reporter ut3.ut_reporter_base := null) is
        begin
          ut3.ut.run(a_reporter);
        end;
      procedure run(a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) is
        begin
          ut3.ut.run(
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          );
        end;
      procedure run(a_path varchar2, a_reporter ut3.ut_reporter_base := null) is
        begin
          ut3.ut.run(a_path, a_reporter);
        end;
      procedure run(a_path varchar2, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) is
        begin
          ut3.ut.run(
              a_path,
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          );
        end;
      procedure run(a_paths ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base := null) is
        begin
          ut3.ut.run(a_paths, a_reporter);
        end;
      procedure run(a_paths ut3.ut_varchar2_list, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) is
        begin
          ut3.ut.run(
              a_paths,
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          );
        end;

      function run(a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (ut3.ut.run(a_reporter));
          return l_results;
        end;
      function run(a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (
            ut3.ut.run(
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          ));
          return l_results;
        end;
      function run(a_path varchar2, a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (ut3.ut.run(a_path, a_reporter));
          return l_results;
        end;
      function run(a_path varchar2, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (
            ut3.ut.run(
              a_path,
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          ));
          return l_results;
        end;
      function run(a_paths ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base := null) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (ut3.ut.run(a_paths, a_reporter));
          return l_results;
        end;
      function run(a_paths ut3.ut_varchar2_list, a_test_files ut3.ut_varchar2_list, a_reporter ut3.ut_reporter_base) return ut3.ut_varchar2_list is
        l_results ut3.ut_varchar2_list;
        begin
          select * bulk collect into l_results from table (
            ut3.ut.run(
              a_paths,
              a_reporter, a_source_files => ut3.ut_varchar2_list(),
              a_test_files => a_test_files
          ));
          return l_results;
        end;
    end test_package_1;
    ]';

    execute immediate q'[create or replace package ut3$user#.test_package_2 is
      --%suite
      --%suitepath(tests.test_package_1)

      --%test
      procedure test1;

      --%test
      procedure test2;

    end test_package_2;
    ]';
    execute immediate q'[create or replace package body ut3$user#.test_package_2 is
      procedure test1 is
        begin
          dbms_output.put_line('test_package_2.test1 executed');
        end;
      procedure test2 is
        begin
          dbms_output.put_line('test_package_2.test2 executed');
        end;
    end test_package_2;
    ]';

    execute immediate q'[create or replace package ut3$user#.test_package_3 is
      --%suite
      --%suitepath(tests2)

      --%test
      procedure test1;

      --%test
      procedure test2;

    end test_package_3;
    ]';
    execute immediate q'[create or replace package body ut3$user#.test_package_3 is
      procedure test1 is
        begin
          dbms_output.put_line('test_package_3.test1 executed');
        end;
      procedure test2 is
        begin
          dbms_output.put_line('test_package_3.test2 executed');
        end;
    end test_package_3;
    ]';
  end;

  procedure drop_ut3$user#_tests is
    pragma autonomous_transaction;
  begin
    execute immediate q'[drop package ut3$user#.test_package_1]';
    execute immediate q'[drop package ut3$user#.test_package_2]';
    execute immediate q'[drop package ut3$user#.test_package_3]';
  end;

  procedure run_proc_no_params is
    l_results clob;
  begin
    execute immediate 'begin ut3$user#.test_package_1.run(); end;';
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_specific_reporter is
    l_results clob;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(:a_reporter); end;'
    using in ut3.ut_documentation_reporter();
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_cov_file_list is
    l_results clob;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(a_test_files=>:a_test_files, a_reporter=>:a_reporter); end;'
    using
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3$user#.test_package_2.pkb%tests/ut3$user#.test_package_1.pkb%tests/ut3$user#.test_package_3.pkb%' );
  end;

  procedure run_proc_pkg_name is
    l_results clob;
  begin
    execute immediate 'begin ut3$user#.test_package_1.run(:a_path); end;'
    using in 'test_package_1';
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_proc_pkg_name_file_list is
    l_results clob;
  begin
    execute immediate 'begin ut3$user#.test_package_1.run(:a_path, :a_test_files, :a_reporter); end;'
    using
      in 'test_package_3',
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3$user#.test_package_3.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3$user#.test_package_1.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3$user#.test_package_2.pkb%' );
  end;

  procedure run_proc_path_list is
    l_results clob;
  begin
    execute immediate 'begin ut3$user#.test_package_1.run(:a_paths); end;'
    using in ut3.ut_varchar2_list(':tests.test_package_1',':tests');
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_proc_path_list_file_list is
    l_results clob;
  begin
    execute immediate 'begin ut3$user#.test_package_1.run(:a_paths, :a_test_files, :a_reporter); end;'
    using
      in ut3.ut_varchar2_list(':tests.test_package_1',':tests'),
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3$user#.test_package_1.pkb%' );
    ut.expect( l_results ).to_be_like( '%tests/ut3$user#.test_package_2.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3$user#.test_package_3.pkb%' );
  end;

  procedure run_proc_null_reporter is
    l_results clob;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(:a_reporter); end;'
    using in cast(null as ut3.ut_reporter_base);
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests%test_package_1%test_package_2%tests2%test_package_3%' );
  end;

  procedure run_proc_null_path is
    l_results clob;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(:a_path); end;'
    using in cast(null as varchar2);
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_null_path_list is
    l_results clob;
    l_paths   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(:a_paths); end;'
    using in l_paths;
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_empty_path_list is
    l_results clob;
  begin
    --Act
    execute immediate 'begin ut3$user#.test_package_1.run(:a_paths); end;'
    using in ut3.ut_varchar2_list();
    l_results := get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_no_params is
    l_results   ut3.ut_varchar2_list;
  begin
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(); end;' using out l_results;
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_specific_reporter is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_reporter); end;'
    using out l_results, in ut3.ut_documentation_reporter();
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_cov_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(a_test_files=>:a_test_files, a_reporter=>:a_reporter); end;'
    using out l_results,
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%tests/ut3$user#.test_package_2.pkb%tests/ut3$user#.test_package_1.pkb%tests/ut3$user#.test_package_3.pkb%' );
  end;

  procedure run_func_pkg_name is
    l_results   ut3.ut_varchar2_list;
  begin
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_path); end;'
    using out l_results, in 'test_package_1';
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_bal%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%test_package_2%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_func_pkg_name_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_path, :a_test_files, :a_reporter); end;'
    using out l_results,
      in 'test_package_3',
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%tests/ut3$user#.test_package_3.pkb%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3$user#.test_package_1.pkb%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3$user#.test_package_2.pkb%' );
  end;

  procedure run_func_path_list is
    l_results   ut3.ut_varchar2_list;
  begin
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_paths); end;'
    using out l_results, in ut3.ut_varchar2_list(':tests.test_package_1',':tests');
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_2%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_func_path_list_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_paths, :a_test_files, :a_reporter); end;'
    using out l_results,
      in ut3.ut_varchar2_list(':tests.test_package_1',':tests'),
      in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
      in ut3.ut_sonar_test_reporter();
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%tests/ut3$user#.test_package_1.pkb%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%tests/ut3$user#.test_package_2.pkb%' );
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3$user#.test_package_3.pkb%' );
  end;

  procedure run_func_null_reporter is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_reporter); end;'
    using out l_results, in cast(null as ut3.ut_reporter_base);
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%tests%test_package_1%test_package_2%tests2%test_package_3%' );
  end;

  procedure run_func_null_path is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_path); end;'
    using out l_results, in cast(null as varchar2);
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_null_path_list is
    l_results   ut3.ut_varchar2_list;
    l_paths   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_paths); end;'
    using out l_results, in l_paths;
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_empty_path_list is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(:a_paths); end;'
    using out l_results, in ut3.ut_varchar2_list();
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_cov_file_lst_null_rep is
    l_results  ut3.ut_varchar2_list;
  begin
    --Act
    execute immediate 'begin :l_results := ut3$user#.test_package_1.run(a_test_files=>:a_test_files, a_reporter=>:a_reporter); end;'
    using out l_results,
    in ut3.ut_varchar2_list('tests/ut3$user#.test_package_1.pkb','tests/ut3$user#.test_package_2.pkb','tests/ut3$user#.test_package_3.pkb'),
    in cast(null as ut3.ut_reporter_base);
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_empty_suite is
    l_results   ut3.ut_varchar2_list;
    l_expected  varchar2(32767);
    pragma autonomous_transaction;
  begin
    --Arrange
    execute immediate q'[create or replace package empty_suite as
      -- %suite

      procedure not_a_test;
    end;]';
    execute immediate q'[create or replace package body empty_suite as
      procedure not_a_test is begin null; end;
    end;]';
    l_expected := '%empty_suite%0 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%';
    --Act
    select * bulk collect into l_results from table(ut3.ut.run('empty_suite'));

    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( l_expected );

    --Cleanup
    execute immediate q'[drop package empty_suite]';
  end;

  procedure create_test_suite is
    l_service_name varchar2(100);
    pragma autonomous_transaction;
  begin
    select global_name into l_service_name from global_name;
    execute immediate
    'create public database link db_loopback connect to ut3_tester identified by ut3
      using ''(DESCRIPTION=
                (ADDRESS=(PROTOCOL=TCP)
                  (HOST='||sys_context('userenv','SERVER_HOST')||')
                  (PORT=1521)
                )
                (CONNECT_DATA=(SERVICE_NAME='||l_service_name||')))''';
    execute immediate q'[
      create or replace package stateful_package as
        function get_state return varchar2;
      end;
    ]';
    execute immediate q'[
      create or replace package body stateful_package as
        g_state varchar2(1) := 'A';
        function get_state return varchar2 is begin return g_state; end;
      end;
    ]';
    execute immediate q'[
      create or replace package test_stateful as
        --%suite
        --%suitepath(test_state)

        --%test
        --%beforetest(acquire_state_via_db_link,rebuild_stateful_package)
        procedure failing_stateful_test;

        procedure rebuild_stateful_package;
        procedure acquire_state_via_db_link;

      end;
    ]';
    execute immediate q'{
    create or replace package body test_stateful as

      procedure failing_stateful_test is
      begin
        ut3.ut.expect(stateful_package.get_state@db_loopback).to_equal('abc');
      end;

      procedure rebuild_stateful_package is
        pragma autonomous_transaction;
      begin
        execute immediate q'[
          create or replace package body stateful_package as
            g_state varchar2(3) := 'abc';
            function get_state return varchar2 is begin return g_state; end;
          end;
        ]';
      end;

      procedure acquire_state_via_db_link is
      begin
        dbms_output.put_line('stateful_package.get_state@db_loopback='||stateful_package.get_state@db_loopback);
      end;
    end;
    }';

  end;

  procedure raise_in_invalid_state is
    l_results   ut3.ut_varchar2_list;
    l_expected  varchar2(32767);
  begin
    --Arrange
    l_expected := 'test_state
  test_stateful
    failing_stateful_test [% sec] (FAILED - 1)%
Failures:%
  1) failing_stateful_test
      ORA-04068: existing state of packages (DB_LOOPBACK%) has been discarded
      ORA-04061: existing state of package body "UT3_TESTER.STATEFUL_PACKAGE" has been invalidated
      ORA-04065: not executed, altered or dropped package body "UT3_TESTER.STATEFUL_PACKAGE"%
      ORA-06512: at line 6%
1 tests, 0 failed, 1 errored, 0 disabled, 0 warning(s)%';

    --Act
    select * bulk collect into l_results from table(ut3.ut.run('test_stateful'));
  
    --Assert
    ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( l_expected );
    ut.fail('Expected exception but nothing was raised');
  exception
    when others then
      ut.expect( ut3.ut_utils.table_to_clob(l_results) ).to_be_like( l_expected );
      ut.expect(sqlcode).to_equal(-4068);
  end;

  procedure drop_test_suite is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package stateful_package';
    execute immediate 'drop package test_stateful';
    begin execute immediate 'drop public database link db_loopback'; exception when others then null; end;
  end;

  procedure run_in_invalid_state is
    l_results   ut3.ut_varchar2_list;
    l_actual    clob;
    l_expected  varchar2(32767);
  begin
    select * bulk collect into l_results from table(ut3.ut.run('failing_invalid_spec'));
    
    l_actual := ut3.ut_utils.table_to_clob(l_results);
    ut.expect(l_actual).to_be_like('%Call params for % are not valid: package does not exist or is invalid: %FAILING_INVALID_SPEC%'); 
    
  end;

  procedure compile_invalid_package is
    ex_compilation_error exception;
    pragma exception_init(ex_compilation_error,-24344);
    pragma autonomous_transaction;
  begin
    begin
      execute immediate q'[
        create or replace package failing_invalid_spec as
        --%suite
        gv_glob_val non_existing_table.id%type := 0;

        --%test
        procedure test1;
      end;]';
    exception when ex_compilation_error then null;
    end;
    begin
      execute immediate q'[
        create or replace package body failing_invalid_spec as
          procedure test1 is begin ut.expect(1).to_equal(1); end;
        end;]';
    exception when ex_compilation_error then null;
    end;
  end;
  procedure drop_invalid_package is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package failing_invalid_spec';
  end;

  procedure run_and_revalidate_specs is
    l_results   ut3.ut_varchar2_list;
    l_actual    clob;
    l_is_invalid number;
  begin
    execute immediate q'[select count(1) from all_objects o where o.owner = :object_owner and o.object_type = 'PACKAGE'
            and o.status = 'INVALID' and o.object_name= :object_name]' into l_is_invalid
            using user,'INVALID_PCKAG_THAT_REVALIDATES';

    select * bulk collect into l_results from table(ut3.ut.run('invalid_pckag_that_revalidates'));
    
    l_actual := ut3.ut_utils.table_to_clob(l_results);
    ut.expect(1).to_equal(l_is_invalid);
    ut.expect(l_actual).to_be_like('%invalid_pckag_that_revalidates%invalidspecs [% sec]%
%Finished in % seconds%
%1 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%'); 
  
  end;

  procedure generate_invalid_spec is
    ex_compilation_error exception;
    pragma exception_init(ex_compilation_error,-24344);
    pragma autonomous_transaction;
  begin
  
    execute immediate q'[
      create or replace package parent_specs as
        c_test constant varchar2(1) := 'Y';
      end;]';
  
    execute immediate q'[
      create or replace package invalid_pckag_that_revalidates as
        --%suite
        g_var varchar2(1) := parent_specs.c_test;

        --%test(invalidspecs)
        procedure test1;
      end;]';

    execute immediate q'[
      create or replace package body invalid_pckag_that_revalidates as
        procedure test1 is begin ut.expect('Y').to_equal(g_var); end;
      end;]';
    
    -- That should invalidate test package and we can then revers
    execute immediate q'[
      create or replace package parent_specs as
        c_test_error constant varchar2(1) := 'Y';
      end;]';
 
    execute immediate q'[
      create or replace package parent_specs as
        c_test constant varchar2(1) := 'Y';
      end;]';

  end;
  procedure drop_invalid_spec is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package invalid_pckag_that_revalidates';
    execute immediate 'drop package parent_specs';
  end;  
  
end;
/

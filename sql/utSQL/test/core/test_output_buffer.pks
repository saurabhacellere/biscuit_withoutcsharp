create or replace package test_output_buffer is

  --%suite(output_buffer)
  --%suitepath(utplsql.core)
  
  --%test(Receives a line from buffer table and deletes)
  procedure test_recieve;
  
  --%test(Does not send line if null text given)
  procedure test_doesnt_send_on_null_text;
  
  --%test(Sends a line into buffer table)
  procedure test_send_line;
  
  --%test(Waits For The Data To Appear For Specified Time)
  procedure test_waiting_for_data;

end test_output_buffer;
/

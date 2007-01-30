class TestFailureParser
  FIND_TEST_FAILURE_REGEX = /^\s+\d+\).*\n(.*)\n\s+\[([\s\S]*?)\]\:\n([\s\S]*?)\n\n/
  def get_test_failures(log)
    testFailures = Array.new
  
    log.gsub(FIND_TEST_FAILURE_REGEX) do |match|
      testFailures <<  TestFailureEntry.new($1, $3, $2)
    end
    
    testFailures
  end
end
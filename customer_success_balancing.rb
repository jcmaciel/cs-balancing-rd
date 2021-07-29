require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
      
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
      raise StandardError, "Limit for CS away not satisfacted" if !limit_cs_away?
      raise StandardError, "Limit for CS exceed (max: 999)" if !limit_cs?
      raise StandardError, "Limit for CUSTOMER exceed (max: 999.999)" if !limit_customer?  

      remove_away
      @customer_success.sort_by!{|cs| cs[:score]}
      @customers.sort_by!{|c| c[:score]}

      ranking = Hash.new(0)
          
      @customers.each do |customer|
          cs_index = 0
          while @customer_success[cs_index][:score] < customer[:score]
              cs_index += 1
              break if cs_index == @customer_success.size
          end
          if cs_index < @customer_success.size
              ranking[@customer_success[cs_index][:id]] += 1
          else
              next
          end
      end
      
      # check if there are cs with the same number of customers
      result = Hash[ranking.select { |k, v| v == ranking.values.max}]
      if result.count > 1 || result.empty?
          return 0
      else
          result.keys[0]
      end
  end

  private
  def remove_away 
    @away_customer_success.each do |cs_away|
      @customer_success.select! {|cs| cs[:id] != cs_away}
    end
  end
  
  def limit_cs_away?
      @away_customer_success.count > (@customer_success.count / 2) ? false : true
  end

  def limit_cs?
      (@customer_success.count >= 1000) ? false : true
  end
    
  def limit_customer?
      (@customers.count >= 1000000) ? false : true
  end
  
    
end

class CustomerSuccessBalancingTests < Minitest::Test
    def test_scenario_one
      balancer = CustomerSuccessBalancing.new(
        build_scores([60, 20, 95, 75]),
        build_scores([90, 20, 70, 40, 60, 10]),
        [2, 4]
      )
      assert_equal 1, balancer.execute
    end
  
    def test_scenario_two
      balancer = CustomerSuccessBalancing.new(
        build_scores([11, 21, 31, 3, 4, 5]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        []
      )
      assert_equal 0, balancer.execute
    end
  
    def test_scenario_three
      balancer = CustomerSuccessBalancing.new(
        build_scores(Array(1..999)),
        build_scores(Array.new(10000, 998)),
        [999]
      )
      result = Timeout.timeout(1.0) { balancer.execute }
      assert_equal 998, result
    end
  
    def test_scenario_four
      balancer = CustomerSuccessBalancing.new(
        build_scores([1, 2, 3, 4, 5, 6]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        []
      )
      assert_equal 0, balancer.execute
    end
  
    def test_scenario_five
      balancer = CustomerSuccessBalancing.new(
        build_scores([100, 2, 3, 3, 4, 5]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        []
      )
      assert_equal 1, balancer.execute
    end
  
    def test_scenario_six
      balancer = CustomerSuccessBalancing.new(
        build_scores([100, 99, 88, 3, 4, 5]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        [1, 3, 2]
      )
      assert_equal 0, balancer.execute
    end
  
    def test_scenario_seven
      balancer = CustomerSuccessBalancing.new(
        build_scores([100, 99, 88, 3, 4, 5]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        [4, 5, 6]
      )
      assert_equal 3, balancer.execute
    end

    def test_scenario_eight
        balancer = CustomerSuccessBalancing.new(
          build_scores([100, 99, 88, 3, 4, 5]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          [2, 3, 4, 5, 6]
        )
        assert_raises(StandardError, "Limit for CS away not satisfacted") {balancer.execute}
    end
    # checks when there is no CS to serve the customer (score above)
    def test_scenario_nine
        balancer = CustomerSuccessBalancing.new(
            build_scores([60, 20, 95, 75]),
            build_scores([190, 20, 70, 40, 60, 10]),
            [2, 4]
        )
        assert_equal 1, balancer.execute
      end
    
      def test_scenario_ten
        balancer = CustomerSuccessBalancing.new(
            build_scores(Array(1..1000)),
            build_scores([190, 20, 70, 40, 60, 10]),
            [2, 4]
        )
        assert_raises(StandardError, "Limit for CS exceed (max: 999)") {balancer.execute}
      end

      def test_scenario_eleven
        balancer = CustomerSuccessBalancing.new(
            build_scores([60, 20, 95, 75]),
            build_scores(Array(1..1000000)),
            [2, 4]
        )
        assert_raises(StandardError, "Limit for CUSTOMER exceed (max: 999.999)") {balancer.execute}
      end
  
    private
  
    def build_scores(scores)
      scores.map.with_index do |score, index|
        { id: index + 1, score: score }
      end
    end
  end
  
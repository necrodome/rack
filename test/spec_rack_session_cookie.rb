require 'test/spec'

require 'rack/session/cookie'
require 'rack/mock'
require 'rack/response'

context "Rack::Session::Cookie" do
  incrementor = lambda { |env|
    env["rack.session"]["counter"] ||= 0
    env["rack.session"]["counter"] += 1
    Rack::Response.new(env["rack.session"].inspect).to_a
  }

  specify "creates a new cookie" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor)).get("/")
    res["Set-Cookie"].should.match("rack.session=")
    res.body.should.equal '{"counter"=>1}'
  end

  specify "loads from a cookie" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor)).get("/")
    cookie = res["Set-Cookie"]
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor)).
      get("/", "HTTP_COOKIE" => cookie)
    res.body.should.equal '{"counter"=>2}'
    cookie = res["Set-Cookie"]
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor)).
      get("/", "HTTP_COOKIE" => cookie)
    res.body.should.equal '{"counter"=>3}'
  end

  specify "survives broken cookies" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor)).
      get("/", "HTTP_COOKIE" => "rack.session=blarghfasel")
    res.body.should.equal '{"counter"=>1}'
  end

  bigcookie = lambda { |env|
    env["rack.session"]["cookie"] = "big" * 3000
    Rack::Response.new(env["rack.session"].inspect).to_a
  }

  specify "barks on too big cookies" do
    lambda {
      Rack::MockRequest.new(Rack::Session::Cookie.new(bigcookie)).
        get("/", :fatal => true)
    }.should.raise(Rack::MockRequest::FatalWarning)
  end
  
  specify "creates a new cookie with integrity hash" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor, :secret => 'test')).get("/")
    res["Set-Cookie"].should.match("rack.session=BAh7BiIMY291bnRlcmkG%0A--827051befe617e14c4142b47d536916b1c1859d698a6366f3a96309a36db2d1ea1b6533d22fbe1af1105a5e2f2da4fd35e7e42836a0c44e7d8aa66dde9202094")
  end
  
  specify "loads from a cookie wih integrity hash" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor, :secret => 'test')).get("/")
    cookie = res["Set-Cookie"]
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor, :secret => 'test')).
      get("/", "HTTP_COOKIE" => cookie)
    res.body.should.equal '{"counter"=>2}'
    cookie = res["Set-Cookie"]
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(incrementor, :secret => 'test')).
      get("/", "HTTP_COOKIE" => cookie)
    res.body.should.equal '{"counter"=>3}'
  end
  
  

end

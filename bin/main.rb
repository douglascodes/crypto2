require './lib/crypto'

s = Solver.new

if ARGV[0]
	s.go_to_work(ARGV[0].to_i)
else
	s.go_to_work()
end


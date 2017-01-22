require 'digest/sha2'

class ProofOfWork
  #@charset = (" ".."~").to_a
  @charset = ("0".."9").to_a

  def self.solve(target,maxlength)
    for i in 1..maxlength+1
      ProofOfWork.chain(ProofOfWork.product(i)) do |candidate|
        hashval = Digest::SHA256.hexdigest(candidate)
        if hashval.start_with?(target)
          return candidate
        end
      end
    end
    return nil
  end

  def self.chain(*iterables)
     for it in iterables
         if it.instance_of? String
             it.split("").each do |i|
                 yield i
             end
         else
             for elem in it
                 yield elem
             end
         end
     end
  end

  def self.product(max)
    strings = 1.upto(max).flat_map do |n|
      @charset.repeated_permutation(n).map(&:join)
    end
  end
end



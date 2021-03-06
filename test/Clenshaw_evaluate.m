function vals = Clenshaw_evaluate(c,x)
%global evals
%evals = evals + 1; 
    bk1 = zeros(size(x));
    bk2 = bk1;
    x = 2*x;
    for k = 1:size(c,1)-1
        bk = c(k) + x.*bk1 - bk2;
        bk2 = bk1;
        bk1 = bk;
    end
    vals = c(end) + .5*x.*bk1 - bk2;
end

%  function Clenshaw_evaluate(c::Vector{Float64},x::Vector{Float64})
%      bk1 = zeros(length(x));
%      bk2 = bk1;
%      x=2*x;
% 
%      for k = 1:length(c)-1
%         bk = c[k] + x.*bk1 - bk2;
%         bk2 = bk1;
%         bk1 = bk;
%     end
% 
%     c[end] + .5*x.*bk1 - bk2
% end
% %
% 
% 
% 
% 
% 
% 
% function clenshawv(c::Vector{Float64},x::Vector{Float64})
%     B = zeros(length(x),length(c)+2);
% 
%     x=2x;
%     
%     for k = length(c):-1:2
%         B[:,k] = c[k] + x.*B[:,k+1] - B[:,k+2];
%     end
%  
%     c[end] + .5*x.*B[:,2] - B[:,3]
% end
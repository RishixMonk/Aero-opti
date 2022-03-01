x1=[2:1:3];

Y = zeros(2,1);
%syms y [2]
for c =1:2
    syms y 
    eqn = y-3*x1(c)-2 ==0;
    Y(c) =solve(eqn,y);
end
    
Y










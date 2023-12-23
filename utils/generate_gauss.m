%% generate 2D gauss function
% By Monster Kid
function output = generate_gauss(height, width, sigma)
    [x, y] = meshgrid(floor(-height/2) + 1:floor(height/2), floor(-width/2) + 1:floor(width/2));
    output = exp(-(x.^2 + y.^2) / (2*sigma^2));
end

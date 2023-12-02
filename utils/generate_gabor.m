%% generate garbor function
function output = generate_gabor(height, width, sigma, angle, frequency, phase)
    sine = generate_sinewave(height, width, angle, frequency, phase);
    gauss = generate_gauss(height, width, sigma);
    output = sine .* gauss;
end

%% generate 2D sine wave
function output = generate_sinewave(height, width, angle, frequency, phase)
    angle = angle * pi / 180;
    phase = phase * pi / 180;
    % [x, y] = meshgrid(1:height, 1:weight);
    [x, y] = meshgrid(floor(-height/2) + 1:floor(height/2), floor(-width/2) + 1:floor(width/2));
    output = sin(2*pi*frequency*(cos(angle)*x + sin(angle)*y) + phase);
end
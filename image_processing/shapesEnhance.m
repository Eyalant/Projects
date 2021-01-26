%This function adds x-shaped noise to the given image,
%then tries to enhance it using a median filter (using myMedian) using
%a 3x3 sized filter. It then returns both the enhanced image and the noisy image.
function [eImg,nImg] = shapesEnhance(img)
    % The noise matrix:
    x_shaped_noise = [1,0,0,0,1;0,1,0,1,0;0,0,1,0,0;0,1,0,1,0;1,0,0,0,1];
    
    % Create a mask and add s&p noise to it:
    mask = zeros(size(img, 1), size(img, 2));
    mask = imnoise(mask, 'salt & pepper', 0.003);
    
    % Perform a convolution between the mask and the shaped noise, then
    % remove the overlapping 1s (=pixels >1) by taking the minimum with 1:
    nImg = min(conv2(mask, x_shaped_noise, 'same'), 1);
    
    % Combine the mask and the image:
    nImg = max(img, nImg);
    
    % Enhance the image using a median filter.
    eImg = myMedian(nImg, 3, 3);
end
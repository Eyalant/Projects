%The function createTiledImage gets two greyscale images and creates a tiled image
%with the dimensions of the big image, where the tiles are the small
%image but with the matching histogram from the big image. Run using
%createTiledImage(bigImage, smallImage) where the arguments are greyscale
%images after imread. The histShape function/script is called from inside the function.
%(if the number of tiles doesn't exactly fit in the big image, it will be tiled as
%much as possible and the remaining non-tile area will remain black.)
function nImg = createTiledImage(bigImage, smallImage)
     % Get the images' size and determine the number of tiles needed:
    [big_rows , big_cols] = size(bigImage);
	[small_rows, small_cols] = size(smallImage);
	number_of_tiles = [big_rows/small_rows, big_cols/small_cols];
    
    % Create the new uint8 image, then iterate over the number of tiles, create a
    % tile from the big image, enhance it using the Histogram Shape
    % algorithm using the small image and place it back in the big image:
	nImg = zeros(size(bigImage), 'uint8');
    for i=0:number_of_tiles(1) - 1
        for j=0:number_of_tiles(2) - 1
                    % Extract a tile (starting with 1:rows and 1:cols in
                    % regards to the small image. Second tile will be (rows+1):(2*rows), (cols+1):(2*cols) and
                    % so on):
            		tile = bigImage( (i*small_rows) + 1 : (i+1)*small_rows, (j*small_cols) + 1 : (j+1)*small_cols);
                    
                    % Enhance the tile using the histogram shape algorithm
                    % using the small image:
            		enhanced_tile = histShape(smallImage, tile);
                    
                    % Place it back into the tile's location in the
                    % picture:
            		nImg((i*small_rows) + 1 : (i+1)*small_rows, (j*small_cols) + 1 : (j+1)*small_cols) = enhanced_tile;
        end
    end
end

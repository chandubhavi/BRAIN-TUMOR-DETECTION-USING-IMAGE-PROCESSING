function BrainTumorStepByStep_GUI
    % Create main GUI figure
    fig = uifigure('Name', 'Brain Tumor Segmentation - Step by Step', ...
                   'Position', [100, 100, 1000, 600]);

    % Axes for each step
    ax1 = uiaxes(fig, 'Position', [50, 420, 200, 150]);    title(ax1, 'Original Image');
    ax2 = uiaxes(fig, 'Position', [270, 420, 200, 150]);   title(ax2, 'Preprocessed (Denoised)');
    ax3 = uiaxes(fig, 'Position', [490, 420, 200, 150]);   title(ax3, 'Brain Mask (Skull Removed)');
    ax4 = uiaxes(fig, 'Position', [710, 420, 200, 150]);   title(ax4, 'Tumor Mask');
    ax5 = uiaxes(fig, 'Position', [270, 220, 460, 160]);   title(ax5, 'Final Tumor Highlighted');

    % Button to load MRI image
    uibutton(fig, 'Text', 'Load MRI Image', ...
        'Position', [100, 50, 150, 40], ...
        'ButtonPushedFcn', @(btn, event) loadImage(ax1));

    % Button to run tumor segmentation
    uibutton(fig, 'Text', 'Run Segmentation', ...
        'Position', [750, 50, 150, 40], ...
        'ButtonPushedFcn', @(btn, event) processImage(ax1, ax2, ax3, ax4, ax5));
end

function loadImage(ax1)
    % Set starting folder to Desktop (platform-independent)
    if ispc
        startFolder = fullfile(getenv('USERPROFILE'), 'Desktop');
    else
        startFolder = fullfile(getenv('HOME'), 'Desktop');
    end

    % Open system file picker
    [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, ...
                             'Select Brain MRI Image', startFolder);

    if isequal(file, 0)
        disp('Image loading canceled.');
        return;
    end

    % Read and show grayscale image
    img = imread(fullfile(path, file));
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    imshow(img, 'Parent', ax1);
    ax1.UserData = img;
end

function processImage(ax1, ax2, ax3, ax4, ax5)
    if isempty(ax1.UserData)
        uialert(ax1.Parent, 'Please load an image first.', 'No Image');
        return;
    end

    img = ax1.UserData;

    % Step 1: Preprocessing - Gaussian Blur
    img_blur = imgaussfilt(img, 2);
    imshow(img_blur, 'Parent', ax2);

    % Step 2: Skull Removal - Thresholding and Morphology
    bw = imbinarize(img_blur, 'adaptive', ...
                    'ForegroundPolarity','bright','Sensitivity',0.4);
    bw = imopen(bw, strel('disk', 5));
    bw_filled = imfill(bw, 'holes');
    brain_mask = bw_filled;
    imshow(brain_mask, 'Parent', ax3);

    % Step 3: Apply Brain Mask
    brain_only = immultiply(img, uint8(brain_mask));

    % Step 4: Tumor Segmentation using Otsu's method
    level = graythresh(brain_only);
    tumor_mask = imbinarize(brain_only, level);
    tumor_mask = bwareaopen(tumor_mask, 50);  % Remove small blobs
    imshow(tumor_mask, 'Parent', ax4);

    % Step 5: Final Tumor Highlight - White tumor on black
    final_result = uint8(255 * tumor_mask);
    imshow(final_result, 'Parent', ax5);
end

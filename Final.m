clc; 
clear all; 
close all;

% เก็บค่าเฉลี่ยของสีทั้งหมด
total_avg_color = [0 0 0];
numImg = 0 ;
LastImg = 31276; % เลขของรูปสุดท้าย

% สำหรับเก็บค่าสีแดงสูงสุดและต่ำสุด
maxRed = 0;
minRed = Inf;
maxRedColor = [];
minRedColor = [];

for i = 24306:LastImg
    filename = sprintf('image/ISIC_00%d.jpg', i);
    
    % ตรวจสอบว่าไฟล์ภาพนี้มีอยู่หรือไม่
    if exist(filename, 'file') == 2
        img = imread(filename);
        
        %นับจำนวนของภาพที่ถูกอ่าน
        numImg = numImg+1;

        % หาขนาดของภาพ
        [rows, cols, ~] = size(img);

        % กำหนดขนาดของบริเวณตรงกลางที่ต้องการคำนวณเฉลี่ย
        center_size = 10; % ขนาดของบริเวณตรงกลาง 100x100 pixels

        % คำนวณพิกเซลเริ่มต้นที่แถวและคอลัมน์ที่เริ่มต้นและสิ้นสุดของบริเวณตรงกลาง
        start_row = floor((rows - center_size) / 2) + 1;
        end_row = start_row + center_size - 1;
        start_col = floor((cols - center_size) / 2) + 1;
        end_col = start_col + center_size - 1;

        % นำสีในบริเวณตรงกลางมาคำนวณค่าเฉลี่ย
        center_region = img(start_row:end_row, start_col:end_col, :);
        avg_color = mean(reshape(center_region, [], 3));

        % ตรวจสอบสีแดงสูงสุดและต่ำสุด
        red_channel = avg_color(1);
        if red_channel > maxRed
            maxRed = red_channel;
            maxRedColor = avg_color;
        end
        if red_channel < minRed
            minRed = red_channel;
            minRedColor = avg_color;
        end

        % เพิ่มค่าเฉลี่ยของสีที่ได้จากภาพนี้เข้าไปในอาร์เรย์
        total_avg_color = total_avg_color + avg_color;

    end
end

% หาค่าเฉลี่ยของผลลัพธ์ทั้งหมด
overall_avg_color = total_avg_color / numImg;
fprintf('Overall average color: R = %.2f, G = %.2f, B = %.2f\n', overall_avg_color(1), overall_avg_color(2), overall_avg_color(3));
fprintf('Image with maximum red: R = %.2f, G = %.2f, B = %.2f\n', maxRedColor(1), maxRedColor(2), maxRedColor(3));
fprintf('Image with minimum red: R = %.2f, G = %.2f, B = %.2f\n', minRedColor(1), minRedColor(2), minRedColor(3));


% อ่านรูปภาพ
image = imread('(BCC)ISIC_0026855.jpg');
%image = imread('ISIC_0025628.jpg');

% แปลงภาพเป็น RGB
if size(image, 3) == 1
    image = cat(3, image, image, image);
end

% ปรับปรุงภาพ (Image Enhancement)
sharpenedImage = imsharpen(image, 'Radius', 5, 'Amount', 5, 'Threshold', 1);
enhancedImage = imadjust(sharpenedImage, [0.1 0.2 0.2; 1 1 1], []);

% หา Mask สำหรับสีแดงของเส้นเลือด
redMask = enhancedImage(:,:,1) > minRedColor(1) & enhancedImage(:,:,2) < minRedColor(2) & enhancedImage(:,:,3) < minRedColor(3);

% สร้าง Mask สำหรับสีแดงจาก Range ที่สอง
redMask2 = enhancedImage(:,:,1) > maxRedColor(1) & enhancedImage(:,:,2) < maxRedColor(2) & enhancedImage(:,:,3) < maxRedColor(1);

% ผสม Mask สีแดงจากทั้งสอง Range เข้าด้วยกัน
finalRedMask = redMask | redMask2;

% ขยายขอบของ Mask สีแดงเพื่อเพิ่มขอบเขต
se = strel('disk', 1);
redMaskExpanded = imdilate(finalRedMask, se); % ขยายขอบ

% ค้นหาขอบของ Mask สีแดงของเส้นเลือด
boundaries = bwboundaries(redMaskExpanded);

% คำนวณพื้นที่ของแต่ละส่วนของ mask
stats = regionprops(redMaskExpanded, 'Area');

% กำหนด threshold สำหรับแบ่งแยกแมสค์เป็นสองชนิด
largeThreshold = 1000; % พื้นที่ใหญ่กว่าหรือเท่ากับ threshold จะถือเป็น mask ที่มีขนาดใหญ่
smallThreshold = 100; % พื้นที่เล็กกว่า threshold จะถือเป็น mask ที่มีขนาดเล็ก

% นับจำนวนพิกเซลของแมสค์ที่มีขนาดใหญ่และเล็ก
numPixelsLarge = sum([stats([stats.Area] >= largeThreshold).Area]);
numPixelsSmall = sum([stats([stats.Area] <= smallThreshold).Area]);

% แสดงผลลัพธ์
disp(['จำนวนพิกเซลของแมสค์ที่มีขนาดใหญ่: ' num2str(numPixelsLarge)]);
disp(['จำนวนพิกเซลของแมสค์ที่มีขนาดเล็ก: ' num2str(numPixelsSmall)]);

% ตรวจสอบตามเงื่อนไขและแยกแยะ Mask ขนาดเล็กและขนาดใหญ่
if numPixelsSmall >(2/10) * (numPixelsLarge + numPixelsSmall)
    disp('เป็นมะเร็งผิวหนังชนิด Basal Cell Carcinoma');
else
    disp('เป็นมะเร็งผิวหนังชนิด Vascular Lesion');
end

% แสดงผลลัพธ์
figure;
imshow(enhancedImage);
hold on;

for k = 1:length(boundaries)
    boundary = boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
end

title('Result');
hold off;
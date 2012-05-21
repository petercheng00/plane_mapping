function does_overlap = box_overlap(b1, b2, band)
    does_overlap = true;
    if(b1.col_min + band > b2.col_max) does_overlap = false; end
    if(b1.col_max - band < b2.col_min) does_overlap = false; end
    if(b1.row_min + band > b2.row_max) does_overlap = false; end
    if(b1.row_max - band < b2.row_min) does_overlap = false; end
end
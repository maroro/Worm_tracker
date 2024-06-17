function Body_Coords = Body_Coordinates(data, S)
    
    frame = data.GFPFrame;
    height_Img = size(frame,1); width_Img = size(frame,2);
    
    xlim([1,width_Img]);
    ylim([1, height_Img]);
    axes(S.ax);
    imshow(frame,[]); colormap (S.ax,'gray');                   
    axis equal tight; hold(S.ax,'on');    

    set(S.bodycoordtext, 'string', 'Select two points separated by worm diameter', ...
        'Fontsize',12);
    drawnow;

    drawnow;
    wd1 = ginput_y(1);
    % plot red cursors passing by the first selected point
    plot(wd1(1),wd1(2),'+m')
    hold(S.ax,'on');
    
    wd2 = ginput_y(1);
    plot(wd2(1),wd2(2),'+c')
    worm_diam=norm(wd2-wd1);
    hold(S.ax,'on');
            
    set(S.bodycoordtext, 'string', 'Select head');
    drawnow;
    [headx, heady] = ginput_y(1);
    head_coords = [headx, heady];
    plot(headx, heady, 'or');
    hold(S.ax,'on');
            
    set(S.bodycoordtext, 'string', 'Select tail');
    drawnow;
    [tailx, taily] = ginput_y(1);
    tail_coords = [tailx taily];
    plot(tailx, taily, 'og');
    hold(S.ax,'on');
    
    set(S.bodycoordtext, 'string', 'Select vulva');
    drawnow;
    [vulvax, vulvay] = ginput_y(1);
    vulva_coords = [vulvax, vulvay];
    plot(vulvax, vulvay, 'om');
    hold(S.ax,'on');

    set(S.bodycoordtext, 'string','');
    drawnow;

    Body_Coords.worm_diam = worm_diam; 
    Body_Coords.head_coords = head_coords; 
    Body_Coords.head_coords = head_coords; 
    Body_Coords.vulva_coords = vulva_coords; 
end
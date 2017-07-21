function err = list_Keithley(device, mode, list)
    input = inputParser;
    addRequired(input,'device');
    addRequired(input,'mode',@(x) any(validatestring(upper(x),{'I','V'})));
    addRequired(input,'list',@(x) isnumeric(x) && ~(size(x,1)>1 && size(x,2>1)) && length(x)>=1 && length(x)<=2500);
    parse(input,device,mode,list)
    
    err = 0;
    try
        length_list = length(list);
        entries = 90;
        list_final = cell(ceil(length_list/entries),1);
        for n0 = 1:ceil(length_list/entries)
            min_temp = 1+(n0-1)*entries;
            max_temp = min(length_list,n0*entries);
            list_temp = list(min_temp:max_temp);
            list_final(n0) = {num2str(list_temp,'%g,')};
        end

        switch upper(mode)
            case 'I'
                %# send list with source settings to device
                for n0 = 1:ceil(length_list/entries)
                    if n0 == 1
                        fprintf(device,':SOUR:LIST:CURR %s',list_final{n0}(1:end-1));
                    else
                        fprintf(device,':SOUR:LIST:CURR:APP %s',list_final{n0}(1:end-1));
                    end
                end
                fprintf(device,':SOUR:CURR:MODE LIST');
            case 'V'
                %# send list with source settings to device
                for n0 = 1:ceil(length_list/entries)
                    if n0 == 1
                        fprintf(device,':SOUR:LIST:VOLT %s',list_final{n0}(1:end-1));
                    else
                        fprintf(device,':SOUR:LIST:VOLT:APP %s',list_final{n0}(1:end-1));
                    end
                end
                fprintf(device,':SOUR:VOLT:MODE LIST');
        end

        %# set start position in list to 1 (optional)
        fprintf(device,':SOUR:LIST:VOLT:STARt 1');

        %# set trigger counts (must be = # sweep points)
        fprintf(device,':TRIG:COUN %s', num2str(length_list));
    catch E
        disp(E.message);
        fE = mfilename('fullpath');
        [~,fN] = fileparts(fE);
        errordlg(['Error in function ',fN]);
        err = 1;
        return;
    end
end


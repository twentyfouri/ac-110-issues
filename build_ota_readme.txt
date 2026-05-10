tar cf ac100-<version>.tar -C mnt flash/ac100 flash/vienna
-C 指定壓縮時的起始目錄
flash/vienna 則是指定相對於起始目錄的檔案名稱
 
壓縮完後假如要刪除某個檔案
tar --delete -f ac100-<version>.tar flash/vienna/nef
刪除掉目標路徑的檔案

xz -z ac110-260225-01.tar
 
壓縮完後假如要增加某個檔案
tar --append -f ac100-<version>.tar --transform='s,.*/,,g' /path/to/zImage
--transform 消除目標檔案的路徑，這樣 zImage 就存在 tar 的根目錄，不加則會變成 /path/to/zImage
 

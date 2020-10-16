# subsetter
【subsetter命令使用说明】
肖斌，2019年11月
        subsetter命令可用来提取FIOCOM数据产品中一个区域的数据，生成到用户指定的路径中。
使用说明：
subsetter /path/to/fiocom/file.nc varname config_file
        该命令目前接受三个参数分别是nc数据路径、变量名和提取配置文件。其中配置文件中设置提取的区域、变量x轴坐标变量(最好给出)、输出路径、输出变量scale_factor off_set等。
使用实例：
cd /home/xiaobin/tools/subsetter
subsetter /SUGONP300-1/FIOCOM/wav_2016-2018/2017090912.wave.nc hs ./test_config
        执行上述命令，将在文件夹/raid2/data_collab1中生成一个区域的有效波高数据文件。
提取配置文件实例：/home/xiaobin/tools/subsetter/test_config：
xregion="x=145.0:165.0"
yregion="y=-15.:-4."
#zregion="z=1:1000"
xcoor=LON
zlev="1,10,20,30,40,50,75,80,100,125,150,200,250,300,400,500" ! 2019/12/25 10:08 
output_dir=/raid2/data_collab1
output_prefix=d17
outtype=short
scale_factor=0.1
outtype可以使用short或者float，

【更新，现在可以做垂向插值了】 2019/12/25 10:09 
如果再配置文件中定义了变量zlev（见上文test_config内容），subsetter将根据其所定义的垂向水深进行插值。
[HJ版本]2020/10/16 14:10
针对温盐流变量（TEM、SAL、CUR、CVR）设置了默认的add_offset和scale_factor，其他变量建议使用outtype=float，不设置add_offset和scale_factor。

【subsetter命令进行nc文件两级压缩】2020年2月21日
subsetter可对nc文件进行两级压缩存储，是指原来采用float或者doule数据类型存储的且未经过netcdf4压缩的nc文件，经过两个步骤：1，数据类型转换成短整型；2，经过netcdf4压缩。经测试，全球FIOCOM数据产品经过两级压缩的数据文件大小比是原来的1/6(原来采用float，且未经netcdf4数据压缩)，大大减少了nc数据占用空间。
subsetter命令可以进行nc文件两级压缩，该程序已经为温盐流变量设置了默认的add_offset和scale_factor，因此配置文件中针对上述变量无需设置这两个参数，会自动输出为相应的短整型数据格式。示例：
cd /home/yinxq/mom5_assi/exec/global.mom.p1L54/work/assi_001/history
subsetter ./20160501.ocean_temp_2016_06_10.nc temp ./test_config
 针对温盐流变量，配置文件中只需设置输出路径和文件前缀即可，cat test_config:
xcoor=XT_OCEAN
output_dir=/raid2/data_collab1
output_prefix=d17

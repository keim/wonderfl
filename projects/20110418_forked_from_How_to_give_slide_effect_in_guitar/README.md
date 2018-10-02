# [forked from: How to give slide effect in guitar](http://fl.corge.net/c/dnn2)

favorite:0 / forked:0

Currently table envelop is one of the solution. But there are only indirect way to create envelop table without MML.  
1. call SiONDriver.setEnvelopTable() to register envelop table  
2. call SiMMLTable.getEnvelopTable() to get SiMMLEnvelopTable instance created internally.  
3. call SiMMLTrack.setPitchEnvelop() to apply envelop curve to the track  
Now the envelop control and pitch bending are stacked on my task of SiON new version. Sorry for inconvenience.   
  
Or, if you can use MML, "&" is simple pitch bending command. http://mmltalks.appspot.com/document/siopm_mml_ref_05_e.html

![thumbnail](./thumbnail.jpg)

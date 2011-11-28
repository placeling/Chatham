class DeleteDuplicatePerspectives < Mongoid::Migration
  def self.up
    
    # These id's were manually identified by running scripts and examining the data
    # No programmatic way to identify them - LINDSAY
    ids_to_delete = [
      "4ed03d3d57b4e3663b000039",
      "4ec5987e6dd9560605000005",
      "4ec598076dd956663d000144",
      "4ec598066dd956663d00013a",
      "4ec5980a6dd956663d00015a",
      "4ec598056dd956663d000130",
      "4ec598066dd956663d000138",
      "4ec598056dd956663d000136",
      "4ec598066dd956663d00013e",
      "4ec5980a6dd956663d00015e",
      "4ec598056dd956663d000132",
      "4ec598086dd956663d00014c",
      "4ec5980a6dd956663d000158",
      "4ea09ce26dd9564a35000064",
      "4e8f3143a6f1ca4b82000042",
      "4e838ea1a6f1ca032b000212",
      "4e8f3146a6f1ca4b82000050",
      "4e8f3ccaa6f1ca6be400001c",
      "4e8f40a3a6f1ca7bfb00005f",
      "4e8f41d3a6f1ca7bfb000123",
      "4e8f41d5a6f1ca7bfb00012a",
      "4e8f3dc0a6f1ca6be4000104",
      "4e8f3dbfa6f1ca6be4000102",
      "4e8f3204a6f1ca4b82000137",
      "4e948c28a6f1ca32ff0000d0",
      "4e8390aba6f1ca0b24000027",
      "4e8f3501a6f1ca55c400002f",
      "4e8f3dbca6f1ca6be40000f7",
      "4e8f3dbca6f1ca6be40000f5",
      "4e8f3dbba6f1ca6be40000f3",
      "4e8f3dbba6f1ca6be40000f1",
      "4e8f3dbaa6f1ca6be40000ef",
      "4e8f3dbaa6f1ca6be40000ed",
      "4e8f3db9a6f1ca6be40000ea",
      "4e8f41dba6f1ca7bfb00013d",
      "4e8cd162a6f1ca23240000e2",
      "4e8cd160a6f1ca23240000db",
      "4e8cd15ba6f1ca23240000c5",
      "4e8cd157a6f1ca23240000b4"
    ]

    ids_to_delete.each do |target|
      perp = Perspective.where(:_id => target)
      
      # Test if exists in case migration run again
      if perp.length > 0
        perp[0].destroy
      end
    end    
  end

  def self.down
  end
end
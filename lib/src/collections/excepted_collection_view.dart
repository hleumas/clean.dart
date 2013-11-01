// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of an minus operation of two collections.
 */
class ExceptedCollectionView extends TransformedDataCollection {
  
  SetOp2<DataView> _srcRefs = new SetOp2<DataView>();
  
  /**
   * Creates a new data collection from [source1] and [source2] only with elements that appear in A but not B. 
   */
  ExceptedCollectionView(DataCollectionView source1, DataCollectionView source2): super(source1, source2, null);
  
  /**
   *  Performs the initial minus operation.
   */
  void _init() {
    
    source1.forEach((DataView d){
      _processSourceAddition(d, 1, silent: true);
    });
    
    source2.forEach((DataView d){
      _processSourceAddition(d, 2, silent: true);
    });
    
  }

  /**
   * When [dataObj] was added to [sourceRef]-th source, this means that maybe [dataObj] needs to be
   * added or removed from this collection. This function detects such cases and adds/removes the 
   * object if needed. If [silent], changes are not logged into [_changeSet] or broadcasted.
   */
  void _processSourceAddition(DataView dataObj,int sourceRef, {bool silent : false}) {
    
    if (_srcRefs.hasRef(dataObj, sourceRef)) return;

    // mark that [dataObj] is in [sourceRef]-th source collection
    _srcRefs.addRef(dataObj, sourceRef);
    
    if (sourceRef == 2) {
      if (_data.contains(dataObj)) {
        _data.remove(dataObj);
        
        if(!silent) {
          _changeSet.markRemoved(dataObj);
        }
      }
    } else { // a ref to source1 was added...
      if (!_srcRefs.hasRef(dataObj, 2)) {
        _data.add(dataObj);
        
        if(!silent) {
          _changeSet.markAdded(dataObj);
        }
      }
    }
  }
      
  void _treatAddedItem(DataView d, int sourceRef) => _processSourceAddition(d, sourceRef);
  
  void _treatRemovedItem(DataView dataObj, int sourceRef) {
    _srcRefs.removeRef(dataObj,sourceRef);
    
    if(_data.contains(dataObj) &&
       (!_srcRefs.hasRef(dataObj, 1) ||
         _srcRefs.hasRef(dataObj, 2))){    

      _changeSet.markRemoved(dataObj);    
      _data.remove(dataObj);
    } else if (!_data.contains(dataObj) && 
               !_srcRefs.hasRef(dataObj, 2) &&
               _srcRefs.hasRef(dataObj, 1)) {
      _changeSet.markAdded(dataObj);
      _data.add(dataObj);
    }
  }
  
  void _treatChangedItem(DataView dataObj, ChangeSet changes, int sourceRef) {
    if (_srcRefs.hasRef(dataObj, 1) &&
        !_srcRefs.hasRef(dataObj, 2)) {
      _changeSet.markChanged(dataObj, changes);
    }
  }  
}

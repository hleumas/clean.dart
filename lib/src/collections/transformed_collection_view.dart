// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataCollection extends DataCollectionView with IterableMixin<DataView>, DataCollectionViewMixin {

  /**
   * The source [DataCollectionView](s) this collection is derived from.
   */
  final List<DataCollectionView> sources;

  TransformedDataCollection(List<DataCollectionView> this.sources) {

    for (var i = 0; i < sources.length; i++) {
      this.sources[i].onChange.listen((ChangeSet changes) => _mergeIn(changes, i));
    }
  }

  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {
    changes.addedItems.forEach((dataObj) => _treatAddedItem(dataObj, sourceNumber));
    changes.removedItems.forEach((dataObj) => _treatRemovedItem(dataObj, sourceNumber));
    changes.changedItems.forEach((dataObj,changes) => _treatChangedItem(dataObj, changes, sourceNumber));
    var items = changes.addedItems.union(changes.removedItems).union(new Set.from(changes.changedItems.keys));
    for (var item in items) {
      _treatItem(item, changes.changedItems[item]);
    }
    _notify();
  }

  // Overridable methods follow
  void _treatAddedItem(DataView dataObj, int sourceNumber) {}
  void _treatRemovedItem(DataView dataObj, int sourceNumber) {}
  void _treatChangedItem(DataView dataObj, ChangeSet c, int sourceNumber) {}
  void _treatItem(dataObj, changeSet) {}
}

/**
 * Provides a multiset-like implementation for up to two occurences.
 */
class SetOp2<E> {

  static const BIT_1 = 1;
  static const BIT_2 = 2;

  /**
   * Information which sources does each data object in the collection appear in. Encoded as bit-array of size 2.
   * Break-down of value meanings:
   *  - 0 object is in neither collection
   *  - 1 (=MASK_SRC1) object is in the first source collection
   *  - 2 (=MASK_SRC2) object is in the second source collection
   *  - 3 (=MASK_SRC1|MASK_SRC2) object is in both collections
   */
  Map<E, int> _refMap = new Map<E,int>();

  /**
   * Returns true iff there is a reference for [key] in [bit].
   */
  bool hasRef(E key, int bit) =>
        _refMap.keys.contains(key) &&
        (_refMap[key] & bit) != 0;


  /**
   * Adds a reference for [key] to a source denoted by [bit].
   */
  void addRef(E key, int bit) {
    if (!_refMap.keys.contains(key)) {
      _refMap[key] = 0;
    }
    _refMap[key] |= bit;
  }

  /**
   * Removes a reference for [key] to source denoted by [bit].
   * True is returned iff there still remains a reference after this operation.
   */
  bool removeRef(E key, int bit) {
    if (!_refMap.keys.contains(key)) return false;

    _refMap[key] &= ~bit;

    if (_refMap[key] == 0) {
      _refMap.remove(key);
      return false;
    }
    return true;
  }

  /**
   * Returns true iff there are exactly two references for [key].
   */
  bool hasBothRefs(E key)
        => hasRef(key, BIT_1) &&
           hasRef(key, BIT_2);

  /**
   * Returns true iff there are no references for [key].
   */
  bool hasNoRefs(E key)
        => !hasRef(key, BIT_1) &&
           !hasRef(key, BIT_2);

  /**
   * Returns true iff there are no references for [key].
   */
  bool hasOneRef(E key)
        => !(hasBothRefs(key) ||
            hasNoRefs(key));

}
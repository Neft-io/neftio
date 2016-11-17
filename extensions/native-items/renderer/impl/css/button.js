const { Item, Native } = Neft.Renderer.Impl.Types;

exports.create = function (data) {
    data.elem = document.createElement('button');
    Item.create.call(this, data);
};

exports.createData = function () {
    return Item.createData();
};

exports.setDSButtonItemText = function(val) {
    this._impl.elem.textContent = val;
    Native.updateNativeSize.call(this);
};

exports.setDSButtonItemTextColor = function(val) {
    this._impl.elemStyle.color = val;
};

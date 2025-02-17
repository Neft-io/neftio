/* global document */
const { util, SignalDispatcher, Renderer: { Impl } } = require('@neft/core')

const { Item } = Impl.Types

exports.create = function (data) {
  Item.create.call(this, data)

  const scrollElem = document.createElement('div')
  data.scrollElem = scrollElem
  scrollElem.style.overflow = 'scroll'
  scrollElem.style.width = '100%'
  scrollElem.style.height = '100%'
  data.elem.appendChild(scrollElem)

  this.onParentChange.connect(() => {
    scrollElem.scrollLeft = this._contentX
    scrollElem.scrollTop = this._contentY
  })

  const setContentX = (val) => {
    const { contentItem } = this._impl
    const max = contentItem ? contentItem._width - this._width : 0
    if (val > max) {
      val = max
    }
    if (val < 0) {
      val = 0
    }

    const oldVal = this.contentX
    if (val !== oldVal) {
      this._impl.onContentXChange.emit(val)
    }
  }

  const setContentY = (val) => {
    const { contentItem } = this._impl
    const max = contentItem ? contentItem._height - this._height : 0
    if (val > max) {
      val = max
    }
    if (val < 0) {
      val = 0
    }

    const oldVal = this.contentY
    if (val !== oldVal) {
      this._impl.onContentYChange.emit(val)
    }
  }

  const syncScroll = () => {
    setContentX(scrollElem.scrollLeft)
    setContentY(scrollElem.scrollTop)
  }

  // safari scroll event throttling fix
  scrollElem.addEventListener(Impl.utils.pointerWheelEventName, (event) => {
    if (event.deltaX != null) {
      setContentX(scrollElem.scrollLeft + event.deltaX)
      setContentY(scrollElem.scrollTop + event.deltaY)
    }
  })

  scrollElem.addEventListener('scroll', syncScroll)
}

exports.createData = function () {
  return util.merge({
    contentItem: null,
    scrollElem: null,
    yScrollbar: false,
    onContentXChange: new SignalDispatcher(),
    onContentYChange: new SignalDispatcher(),
  }, Item.DATA)
}

exports.setScrollableContentItem = (function () {
  function onHeightChange() {
    const data = this._impl
    const { contentItem } = this
    if (contentItem._height <= this._height) {
      if (data.yScrollbar) {
        data.scrollElem.style.overflowY = 'hidden'
        data.yScrollbar = false
      }
    } else if (!data.yScrollbar) {
      data.scrollElem.style.overflowY = 'scroll'
      data.yScrollbar = true
    }
  }

  return function (val) {
    const oldVal = this._impl.contentItem
    if (oldVal != null) {
      if (oldVal._impl.elem.parentElement === this._impl.scrollElem) {
        this._impl.scrollElem.removeChild(oldVal._impl.elem)
      }
      oldVal.onHeightChange.disconnect(onHeightChange, this)
    }

    if (val != null) {
      val.onHeightChange.connect(onHeightChange, this)
      this._impl.contentItem = val
      this._impl.scrollElem.appendChild(val._impl.elem)
    }
  }
}())

exports.setScrollableContentX = function (val) {
  this._impl.scrollElem.scrollLeft = val
}

exports.setScrollableContentY = function (val) {
  this._impl.scrollElem.scrollTop = val
}

Impl.addTypeImplementation('Scrollable', exports)

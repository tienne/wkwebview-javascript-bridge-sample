(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define('window', root);
    define(['window'], factory);
  } else {
    root.wadInterface = factory(root, window);
  }
}(typeof self !== 'undefined' ? self : this, function(window) {
  /**
   * native js interface
   * @typedef {wadInterface}
   */
  var wadInterface = {
    /**
     * @private
     * 네이티브로 실행할 함수의 콜백 아이디
     * 고유한 아이디를 가지고, 새로고침해도 겹치지 않도록 random 값을 준다.
     */
    callbackId: Math.floor(Math.random() * 2000000000),
    /**
     * @private
     * 실행한 함수가 콜백을 실행하기 전까지, 콜백을 저장한다.
     */
    callbacks: {},
    /**
     * @private
     * 이벤트 리스너를 보관
     */
    listeners: {},

    /**
     * 네이티브에서 이벤트가 발생시 호출할 함수
     * @param { string } eventName 이벤트명
     * @param { Object? } args 이벤트에 넘겨줄 파라미터
     */
    fromNativeEvent: function (eventName, args) {
      var listeners = this.listeners[eventName];

      if (!listeners || !listeners?.length > 0) {
        return;
      }

      listeners.forEach(listener => listener(args));
    },
    /**
     *
     * @param {string} eventName
     * @param {function} callback
     * @return {Promise}
     */
    addListener(eventName, callback) {
      var listeners = this.listeners[eventName];
      if (!listeners) {
        this.listeners[eventName] = [];
      }

      this.listeners[eventName].push(callback);

      const remove = async () => this.removeListener(eventName, callback);

      const promise = Promise.resolve({ remove });

      Object.defineProperty(promise, 'remove', {
        value: async () => {
          await remove();
        }
      });

      return promise;
    },

    /**
     *
     * @param {string} eventName
     * @param {function} callback
     * @return {Promise<void>}
     */
    async removeListener(eventName, callback) {
      var listeners = this.listeners[eventName];
      if (!listeners) {
        return;
      }

      var index = listeners.indexOf(callback);
      this.listeners[eventName].splice(index, 1);

      if (!this.listeners[eventName].length) {

      }
    },

    /**
     * 네이티브에서 커맨드를 실행한 후, 네이티브 코드가 호출한다.
     * @param {number} callbackId - 실행할 때 네이티브에 전송했던 콜백 아이디
     * @param {boolean} isSuccess - 커맨드가 성공적으로 실행되었는지 여부
     * @param {Object} args - 네이티브에서 전송하는 JSON 객체
     */
    fromNative: function(callbackId, isSuccess, args) {
      var callback = window.wadInterface.callbacks[callbackId];
      if (callback) {
        if (isSuccess) {
          if (callback.success) {
            callback.success.apply(null, [args]);
          }
        } else if (!isSuccess) {
          if (callback.fail) {
            callback.fail.apply(null, [args]);
          }
        }

        delete window.wadInterface.callbacks[callbackId];
      }
    },
    /**
     * 네이티브에 필요한 액션을 실행시킨다.
     * 웹 프론트엔드에서 실행해 네이티브로 명령을 넘긴다.
     * @param {string} action - 어떤 액션인지 구분하는 값
     * @param {Object?} actionArgs - 액션의 인자
     * @param {Function?} [successCallback] - 액션이 성공했을 때 불리는 함수 객체
     * @param {Function?} [failCallback] -  액션이 실패했을 때 불리는 함수 객체
     */
    toNative: function(action, actionArgs, successCallback, failCallback) {
      var callbackId = null;

      if (successCallback || failCallback) {
        callbackId = window.wadInterface.callbackId;
        window.wadInterface.callbackId += 1;
        window.wadInterface.callbacks[callbackId] = { success: successCallback, fail: failCallback };
      }

      actionArgs = actionArgs || {};
      if (window.wadInterface.platform() === 'ios') {
        window.wadInterface.iosCommand(callbackId, action, actionArgs);
      } else if (window.wadInterface.platform() === 'aos') {
        window.wadInterface.aosCommand(callbackId, action, actionArgs);
      }
    },

    /**
     * 네이티브에 필요한 액션을 실행시킨다.
     * 웹 프론트엔드에서 실행해 네이티브로 명령을 넘긴다.
     * @param {string} action - 어떤 액션인지 구분하는 값
     * @param {Object?} actionArgs - 액션의 인자
     */
    toNativePromise: function(action, actionArgs) {
      return new Promise((resolve, reject) => {
        this.toNative(action, actionArgs,
          (data) => {
            resolve(data);
          },
          (data) => {
            reject(data);
          });
      });
    },

    /**
     * 현재 플랫폼 상태
     */
    platform: function() {
      if (window.hasOwnProperty('AndroidWadInterface')) {
        return 'aos';
      } else if(
        window.hasOwnProperty('webkit') &&
        window.webkit.messageHandlers &&
        window.webkit.messageHandlers.hasOwnProperty('wadInterface')
      ) {
        return 'ios';
      }
      return 'web';
    },
    /**
     * interface 지원 버전인지 여부
     * @return {boolean}
     */
    supportVersion: function() {
      return window.hasOwnProperty('AndroidWadInterface') ||
        (
          window.hasOwnProperty('webkit') &&
          window.webkit.messageHandlers &&
          window.webkit.messageHandlers.hasOwnProperty('wadInterface')
        );
    },
    /**
     * @private
     *
     * iOS WKWebView에 스크립트 메시지를 전송하여 명령을 전송한다.
     * @param {number} callbackId - 콜백을 추적하기 위한 아이디
     * @param {string} action - 어떤 액션인지 구분하는 값
     * @param {Object} actionArgs - 액션의 인자
     */
    iosCommand: function(callbackId, action, actionArgs) {
      var callbackIdString = (callbackId && callbackId.toString()) || null;
      var message = { callbackId: callbackIdString, action: action, actionArgs: actionArgs };
      window.webkit.messageHandlers.wadInterface.postMessage(message);
    },

    /**
     * @private
     *
     * AOS WebView에 Javascript Interface를 실행하여 명령을 전송한다.
     * @param {number} callbackId - 콜백을 추적하기 위한 아이디
     * @param {string} action - 어떤 액션인지 구분하는 값
     * @param {Object} actionArgs - 액션의 인자
     */
    aosCommand: function(callbackId, action, actionArgs) {
      var actionArgsStringfy = JSON.stringify(actionArgs);
      var callbackIdString = callbackId.toString();
      window.AndroidWadInterface.postAction(callbackIdString, action, actionArgsStringfy);
    },
  };

  wadInterface.mode = 'production';

  return wadInterface;
}));

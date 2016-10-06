package com.zegenie.plugin.InAppBrowserXwalk;

import com.zegenie.plugin.InAppBrowserXwalk.BrowserDialog;

import android.content.res.Resources;
import org.apache.cordova.*;
import org.apache.cordova.PluginManager;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import org.xwalk.core.XWalkView;
import org.xwalk.core.XWalkResourceClient;
import org.xwalk.core.XWalkCookieManager;
import org.xwalk.core.XWalkNavigationHistory;
import org.xwalk.core.JavascriptInterface;

import android.view.View;
import android.view.Window;
import android.view.Gravity;
import android.view.WindowManager;
import android.view.WindowManager.LayoutParams;
import android.content.Context;
import android.app.Activity;
import android.webkit.ValueCallback;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import android.util.Log;

import android.view.WindowManager;
import android.view.WindowManager.LayoutParams;
import java.io.ByteArrayOutputStream;
import java.util.Arrays;


public class InAppBrowserXwalk extends CordovaPlugin {

    private BrowserDialog[] dialogs = new BrowserDialog[6];
    private XWalkView[] xWalkWebViews = new XWalkView[6];
    private CallbackContext callbackContext;
    private XWalkCookieManager xWalkCookieManager;

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
      if (action.equals("open")) {
        this.callbackContext = callbackContext;
        this.openBrowser(data);
      }

      if (action.equals("load")) {
        if (this.callbackContext == null) this.callbackContext = callbackContext;
        this.loadUrl(data);
      }

      if (action.equals("close")) {
        this.closeBrowser(data);
      }

      if (action.equals("show")) {
        this.showBrowser(data);
      }

      if (action.equals("hide")) {
        this.hideBrowser(data);
      }

      if (action.equals("setSize")) {
        this.setSize(data);
      }

      if (action.equals("setPosition")) {
        this.setPosition(data);
      }

      if (action.equals("executeScript")) {
        this.injectJS(data);
      }

      if (action.equals("getScreenshot")) {
        this.getScreenshot(data);
      }

      return true;
    }

    class MyResourceClient extends XWalkResourceClient {
      private int index;

      MyResourceClient(XWalkView view, int index) {
         super(view);
         this.index = index;
      }

      @Override
      public void onLoadStarted (XWalkView view, String url) {
         try {
           JSONObject obj = new JSONObject();
           obj.put("type", "loadstart");
           obj.put("url", url);
           obj.put("index", this.index);
           PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
           result.setKeepCallback(true);
           callbackContext.sendPluginResult(result);
         } catch (JSONException ex) {}
      }

      @Override
      public void onLoadFinished (XWalkView view, String url) {
         try {
           JSONObject obj = new JSONObject();
           obj.put("type", "loadstop");
           obj.put("url", url);
           obj.put("index", this.index);
           PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
           result.setKeepCallback(true);
           callbackContext.sendPluginResult(result);
         } catch (JSONException ex) {}
       }
   }

   class JsInterface {
     private int index;

     JsInterface(int index) {
       this.index = index;
     }

     @JavascriptInterface
     public void send(String data) {
       try {
         JSONObject obj = new JSONObject();
         obj.put("type", "jsMessage");
         obj.put("index", this.index);
         obj.put("data", data);
         PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
         result.setKeepCallback(true);
         callbackContext.sendPluginResult(result);
       } catch (JSONException ex) {}
     }
   }

   private void openBrowser(final JSONArray data) throws JSONException {
    final int index = data.getInt(0);
    final String url = data.getString(1);

    if (dialogs[index] != null) {
      this.loadUrl(data);
      return;
    }

    this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          // parsing options first
          int left=10, top=10, width=100, height=100;
          float alpha=1f;

          if(data != null && data.length() >= 2) {
            try {
             // Options will be like : left=0,top=150,width=320,height=200
             String paramString = data.getString(2);
             Log.i("openBrowser string", paramString);
             String[] params = paramString.split(",");

             for (int i = 0; i < params.length; i++) {
               String[] keyValue = params[i].split("=");

               if (keyValue.length >= 2) {
                 String paramKey = keyValue[0];
                 String paramVal = keyValue[1];

                 if (paramKey.compareTo("left") == 0) {
                    left = Integer.parseInt(paramVal);
                 } else if (paramKey.compareTo("top") == 0) {
                    top = Integer.parseInt(paramVal);
                 } else if (paramKey.compareTo("width") == 0) {
                    width = Integer.parseInt(paramVal);
                 } else if (paramKey.compareTo("height") == 0) {
                    height = Integer.parseInt(paramVal);
                 } else if (paramKey.compareTo("alpha") == 0) {
                    alpha = Float.parseFloat(paramVal);
                 }
               }
             }
            } catch (JSONException ex) {
              String msg = ex.getMessage();
            }
          }

          // create dialog and xwalk
          BrowserDialog dialog = new BrowserDialog(cordova.getActivity(), android.R.style.Theme_NoTitleBar);
          XWalkView xWalkWebView = new XWalkView(cordova.getActivity(), cordova.getActivity());

          // to enable JS bridge
          xWalkWebView.addJavascriptInterface(new JsInterface(index), "AppInterface");

          if (xWalkCookieManager == null) {
            xWalkCookieManager = new XWalkCookieManager();
            xWalkCookieManager.setAcceptCookie(true);
            xWalkCookieManager.setAcceptFileSchemeCookies(true);
          }

          xWalkWebView.setResourceClient(new MyResourceClient(xWalkWebView, index));
          xWalkWebView.load(url == null ? "about:blank" : url, "");

          dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
          dialog.setCancelable(true);

          Window dialogWindow = dialog.getWindow();
          dialogWindow.setGravity(Gravity.LEFT | Gravity.TOP);
          dialogWindow.addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL);
          dialogWindow.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
          dialogWindow.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);

          WindowManager.LayoutParams layoutParams = dialogWindow.getAttributes();
          layoutParams.windowAnimations = android.R.style.Animation_Dialog;
          layoutParams.x = left; // The new position of the X coordinates
          layoutParams.y = top; // The new position of the Y coordinates
          layoutParams.width = width; // Width
          layoutParams.height = height; // Height
          layoutParams.alpha = alpha; // Transparency

          dialogWindow.setAttributes(layoutParams);
          dialog.addContentView(xWalkWebView, layoutParams);

          dialogs[index] = dialog;
          xWalkWebViews[index] = xWalkWebView;
        }
      });
    }


    public void loadUrl(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      final String url = data.getString(1);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if (xWalkWebViews[index] != null) xWalkWebViews[index].load(url,"");
        }
      });
    }

    public void injectJS(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      final String script = data.getString(1);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if (xWalkWebViews[index] == null) return;
          xWalkWebViews[index].evaluateJavascript(script, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String scriptResult) {
              try {
                JSONObject obj = new JSONObject();
                obj.put("type", "jsCallback");
                obj.put("index", index);
                obj.put("data", scriptResult);
                PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
              } catch (JSONException ex) {}
            }
          });
        }
      });
    }

    // Set the width and height parameter. Data : WIDTH, HIGHT
    public void setSize(JSONArray data)  throws JSONException {
      final int index = data.getInt(0);
      final int width = data.getInt(1);
      final int height = data.getInt(2);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            if(dialogs[index] == null) return;

            Window dialogWindow = dialogs[index].getWindow();
            WindowManager.LayoutParams layoutParams = dialogWindow.getAttributes();
            layoutParams.width = width;
            layoutParams.height = height;
            dialogWindow.setAttributes(layoutParams);
	          dialogs[index].setContentView(xWalkWebViews[index], layoutParams);
        }
      });
    }

    // Set the left and top parameter. Data : LEFT, TOP
    public void setPosition(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      final int left = data.getInt(1);
      final int top = data.getInt(2);

      this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            BrowserDialog dialog = dialogs[index];
            XWalkView xWalkWebView = xWalkWebViews[index];
            if(dialog == null) return;

            Window dialogWindow = dialog.getWindow();
            WindowManager.LayoutParams layoutParams = dialogWindow.getAttributes();
            layoutParams.x = left; // The new position of the X coordinates
            layoutParams.y = top; // The new position of the Y coordinates
            dialogWindow.setAttributes(layoutParams);
            dialog.setContentView(xWalkWebView, layoutParams);
          }
      });
    }

    public void getScreenshot(JSONArray data)  throws JSONException {
      final int index = data.getInt(0);
      final int quality = data.getInt(1);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            if (xWalkWebViews[index] == null) return;
            Bitmap bitmap = getBitmapFromView(xWalkWebViews[index]);
            String base64Image = bitMapToString(bitmap, quality);

            try {
              JSONObject obj = new JSONObject();
              obj.put("type", "onScreenshot");
              obj.put("index", index);
              obj.put("data", base64Image);
              PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
              result.setKeepCallback(true);
              callbackContext.sendPluginResult(result);
            } catch (JSONException ex) {}
          }
      });
    }

    private Bitmap getBitmapFromView(View view) {
        //Define a bitmap with the same size as the view
        Bitmap returnedBitmap = Bitmap.createBitmap(view.getWidth(), view.getHeight(), Bitmap.Config.ARGB_8888);
        //Bind a canvas to it
        Canvas canvas = new Canvas(returnedBitmap);
        //Get the view's background
        Drawable bgDrawable = view.getBackground();
        if (bgDrawable != null)
            //has background drawable, then draw it on the canvas
            bgDrawable.draw(canvas);
        else
            //does not have background drawable, then draw white background on the canvas
            canvas.drawColor(Color.WHITE);

        // draw the view on the canvas
        view.draw(canvas);
        //return the bitmap
        return returnedBitmap;
    }

    private String bitMapToString(Bitmap bitmap, int quality) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, baos);
        byte[] b = baos.toByteArray();
        String temp = null;
        try {
            System.gc();
            temp = Base64.encodeToString(b, Base64.DEFAULT);
        } catch (Exception e) {
            e.printStackTrace();
        } catch (OutOfMemoryError e) {
            baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, 50, baos);
            b = baos.toByteArray();
            temp = Base64.encodeToString(b, Base64.DEFAULT);
            Log.e("bitMapToString", "Out of memory error catched");
        }
        return temp;
    }

    public void hideBrowser(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if(dialogs[index] != null) dialogs[index].hide();
        }
      });
    }

    public void showBrowser(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if(dialogs[index] != null) dialogs[index].show();
        }
      });
    }

    public void closeBrowser(JSONArray data) throws JSONException {
      final int index = data.getInt(0);
      this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            BrowserDialog dialog = dialogs[index];
            XWalkView xWalkWebView = xWalkWebViews[index];
            if(dialog == null) return;

            xWalkWebView.onDestroy();
            dialog.dismiss();
            dialogs[index] = null;
            xWalkWebViews[index] = null;
            try {
              JSONObject obj = new JSONObject();
              obj.put("type", "exit");
              obj.put("index", index);
              PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
              result.setKeepCallback(true);
              callbackContext.sendPluginResult(result);
            } catch (JSONException ex) {}
          }
      });
    }

// Check if browser has history
    public void hasHistory(JSONArray data)  throws JSONException {
		final int index = data.getInt(0);
		this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
				String ret="0";
				XWalkView xWalkWebView = xWalkWebViews[index];
				Boolean res = xWalkWebView.getNavigationHistory().canGoBack();
				if (res) {ret="1";}
				try {
              		JSONObject obj = new JSONObject();
              		obj.put("type", "history");
              		obj.put("index", index);
              		obj.put("data", ret);
              		PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
              		result.setKeepCallback(true);
              		callbackContext.sendPluginResult(result);
            	} catch (JSONException ex) {}
            }
        });
    }
	
	// goBack in history
    public void goBack(JSONArray data) throws JSONException {
		final int index = data.getInt(0);
		this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (xWalkWebViews[index]==null) return;
				if (xWalkWebViews[index].getNavigationHistory().canGoBack())
					xWalkWebViews[index].getNavigationHistory().navigate(XWalkNavigationHistory.Direction.BACKWARD, 1);
					}
        });
    }
	
	@Override
	protected void onPause() {
		super.onPause();
		for (int i = 0; i < 6; i++) 
			if (xWalkWebViews[i] != null) {
				xWalkWebViews[i].pauseTimers();
				xWalkWebViews[i].onHide();
			}
	}
	
	
	@Override
	protected void onResume() {
		super.onResume();
		for (int i = 0; i < 6; i++) 
			if (xWalkWebViews[i] != null) {
				xWalkWebViews[i].resumeTimers();
				xWalkWebViews[i].onShow();
			}
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		for (int i = 0; i < 6; i++) 
			if (xWalkWebViews[i] != null) {
				xWalkWebViews[i].onDestroy();
			}
	}
	/*
	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		for (int i = 0; i < 6; i++) 
			if (xWalkWebViews[i] != null) {
				xWalkWebViews[i].onActivityResult(requestCode, resultCode, data);
			}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		for (int i = 0; i < 6; i++) 
			if (xWalkWebViews[i] != null) {
			   xWalkWebViews[i].onNewIntent(intent);
			}
	}
	*/
}

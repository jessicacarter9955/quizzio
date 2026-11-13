import React, {useCallback, useEffect, useRef, useState} from 'react';
import {ActivityIndicator, BackHandler, Linking, Platform, Pressable, SafeAreaView, StatusBar, StyleSheet, Text, View} from 'react-native';
import {WebView} from 'react-native-webview';

const URL = 'https://quizlab-responsive-web.onrender.com/paper-trading/';
const BG = '#131722';
const BLUE = '#2962ff';

export default function App() {
  const ref = useRef<WebView>(null);
  const [isLoading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);
  const [canGoBack, setCanGoBack] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);

  const back = useCallback(() => {
    // Close the actual TradingView full-screen modal before attempting WebView history.
    ref.current?.injectJavaScript('if(window.tradingCloseAdvanced && document.getElementById("pt-advanced-overlay")){window.tradingCloseAdvanced()}else if(history.length>1){history.back()};true;');
    return true;
  }, [canGoBack]);

  useEffect(() => {
    if (Platform.OS !== 'android') return;
    const listener = BackHandler.addEventListener('hardwareBackPress', back);
    return () => listener.remove();
  }, [back]);

  const reload = () => {
    setFailed(false);
    setLoading(true);
    setReloadKey(v => v + 1);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={BG} />
      <View style={styles.root}>
        {failed ? (
          <View style={styles.error}>
            <Text style={styles.heading}>VERGE is offline</Text>
            <Text style={styles.copy}>A connection is required for market prices, student accounts, and charts.</Text>
            <Pressable onPress={reload} style={styles.retry} accessibilityRole="button" accessibilityLabel="Retry connection">
              <Text style={styles.retryLabel}>Retry</Text>
            </Pressable>
          </View>
        ) : (
          <WebView
            key={reloadKey}
            ref={ref}
            source={{uri: URL}}
            style={styles.webview}
            originWhitelist={['https://*']}
            allowsInlineMediaPlayback
            mediaPlaybackRequiresUserAction={false}
            mixedContentMode="never"
            thirdPartyCookiesEnabled
            sharedCookiesEnabled
            javaScriptEnabled
            domStorageEnabled
            setSupportMultipleWindows={false}
            allowsBackForwardNavigationGestures
            pullToRefreshEnabled={Platform.OS === 'android'}
            onLoadStart={() => setLoading(true)}
            onLoadEnd={() => setLoading(false)}
            onError={() => {setLoading(false); setFailed(true);}}
            onHttpError={({nativeEvent}) => {
              if (nativeEvent.statusCode >= 500 && nativeEvent.url.startsWith(URL)) setFailed(true);
            }}
            onNavigationStateChange={state => setCanGoBack(state.canGoBack)}
            onShouldStartLoadWithRequest={req => {
              // External pages open in the system browser; never navigate away from student UI.
              if (req.url.startsWith('https://quizlab-responsive-web.onrender.com/paper-trading/') ||
                  req.url.startsWith('about:blank')) return true;
              if (req.isTopFrame) { void Linking.openURL(req.url); return false; }
              return true;
            }}
          />
        )}
        {isLoading && !failed && (
          <View style={styles.loading} pointerEvents="none">
            <ActivityIndicator size="large" color={BLUE}/>
            <Text style={styles.loadingText}>Loading VERGE…</Text>
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {flex:1,backgroundColor:BG},
  root: {flex:1,backgroundColor:BG},
  webview: {flex:1,backgroundColor:BG},
  loading: {position:'absolute',top:0,left:0,right:0,bottom:0,alignItems:'center',justifyContent:'center',backgroundColor:BG},
  loadingText: {color:'#9598a1',fontSize:13,marginTop:16},
  error: {flex:1,alignItems:'center',justifyContent:'center',padding:30},
  heading: {fontSize:22,color:'#f5f7fc',fontWeight:'700',marginBottom:12},
  copy: {color:'#9598a1',textAlign:'center',fontSize:13,lineHeight:21,marginBottom:24},
  retry: {backgroundColor:BLUE,paddingHorizontal:28,paddingVertical:12,borderRadius:10},
  retryLabel: {color:'white',fontWeight:'700',fontSize:14},
});

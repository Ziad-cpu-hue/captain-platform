import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text } from 'react-native';
import { Colors } from '../theme';
import { useAuthStore } from '../store';

import SplashScreen from '../screens/auth/SplashScreen';
import LoginScreen from '../screens/auth/LoginScreen';
import HomeScreen from '../screens/customer/HomeScreen';
import OrderMapScreen from '../screens/customer/OrderMapScreen';
import OrderSummaryScreen from '../screens/customer/OrderSummaryScreen';
import OrderTrackingScreen from '../screens/customer/OrderTrackingScreen';
import OrderHistoryScreen from '../screens/customer/OrderHistoryScreen';
import CaptainHomeScreen from '../screens/captain/CaptainHomeScreen';
import CaptainApplyScreen from '../screens/captain/CaptainApplyScreen';
import ChatScreen from '../screens/shared/ChatScreen';
import ProfileScreen from '../screens/shared/ProfileScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function TabIcon({ icon, focused }: { icon: string; focused: boolean }) {
  return <Text style={{ fontSize: 21, opacity: focused ? 1 : 0.4 }}>{icon}</Text>;
}

function CustomerTabs() {
  return (
    <Tab.Navigator screenOptions={{ headerShown: false, tabBarActiveTintColor: Colors.primary, tabBarInactiveTintColor: Colors.textLight, tabBarLabelStyle: { fontSize: 10, fontWeight: '600' }, tabBarStyle: { borderTopColor: Colors.border, backgroundColor: Colors.white, paddingBottom: 4, height: 58 } }}>
      <Tab.Screen name="HomeTab" component={HomeScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="🏠" focused={p.focused} />, tabBarLabel: 'Home' }} />
      <Tab.Screen name="History" component={OrderHistoryScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="📋" focused={p.focused} />, tabBarLabel: 'History' }} />
      <Tab.Screen name="ChatSupport" component={ChatScreen} initialParams={{ threadId: 'support', title: 'Support' }} options={{ tabBarIcon: (p: any) => <TabIcon icon="💬" focused={p.focused} />, tabBarLabel: 'Chat' }} />
      <Tab.Screen name="ProfileTab" component={ProfileScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="👤" focused={p.focused} />, tabBarLabel: 'Profile' }} />
    </Tab.Navigator>
  );
}

function CaptainTabs() {
  return (
    <Tab.Navigator screenOptions={{ headerShown: false, tabBarActiveTintColor: Colors.primary, tabBarInactiveTintColor: Colors.textLight, tabBarLabelStyle: { fontSize: 10, fontWeight: '600' }, tabBarStyle: { borderTopColor: Colors.border, backgroundColor: Colors.white, paddingBottom: 4, height: 58 } }}>
      <Tab.Screen name="CaptainHomeTab" component={CaptainHomeScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="🏠" focused={p.focused} />, tabBarLabel: 'Home' }} />
      <Tab.Screen name="CaptainHistory" component={OrderHistoryScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="📋" focused={p.focused} />, tabBarLabel: 'History' }} />
      <Tab.Screen name="CaptainChatSupport" component={ChatScreen} initialParams={{ threadId: 'support', title: 'Support' }} options={{ tabBarIcon: (p: any) => <TabIcon icon="💬" focused={p.focused} />, tabBarLabel: 'Chat' }} />
      <Tab.Screen name="CaptainProfileTab" component={ProfileScreen} options={{ tabBarIcon: (p: any) => <TabIcon icon="👤" focused={p.focused} />, tabBarLabel: 'Profile' }} />
    </Tab.Navigator>
  );
}

export default function Navigation() {
  const { user, isLoading } = useAuthStore();
  if (isLoading) return null;

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false, animation: 'slide_from_right' }}>
        {!user ? (
          <>
            <Stack.Screen name="Splash" component={SplashScreen} />
            <Stack.Screen name="Login" component={LoginScreen} options={{ animation: 'fade' }} />
          </>
        ) : user.role === 'captain' ? (
          <>
            <Stack.Screen name="CaptainTabs" component={CaptainTabs} />
            <Stack.Screen name="OrderTracking" component={OrderTrackingScreen} />
            <Stack.Screen name="Chat" component={ChatScreen} />
          </>
        ) : (
          <>
            <Stack.Screen name="CustomerTabs" component={CustomerTabs} />
            <Stack.Screen name="OrderMap" component={OrderMapScreen} />
            <Stack.Screen name="OrderSummary" component={OrderSummaryScreen} />
            <Stack.Screen name="OrderTracking" component={OrderTrackingScreen} />
            <Stack.Screen name="CaptainApply" component={CaptainApplyScreen} />
            <Stack.Screen name="Chat" component={ChatScreen} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

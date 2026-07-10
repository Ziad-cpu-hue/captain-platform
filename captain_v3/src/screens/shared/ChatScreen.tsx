import React, { useState, useEffect, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, FlatList, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation, useRoute } from '@react-navigation/native';
import { Colors, Spacing, Radius, FontSize } from '../../theme';
import { sendMessage, onMessages } from '../../services/firebase';
import { useAuthStore } from '../../store';

const DEMO_MESSAGES = [
  { id: '1', senderId: 'captain_demo', senderName: 'Captain Ahmed', text: 'Hello! I am on my way to your location.', createdAt: new Date(Date.now() - 120000) },
  { id: '2', senderId: 'demo_user_001', senderName: 'You', text: 'Great! I am waiting at the main entrance.', createdAt: new Date(Date.now() - 60000) },
  { id: '3', senderId: 'captain_demo', senderName: 'Captain Ahmed', text: 'I will be there in 3 minutes. My car is a white Toyota.', createdAt: new Date(Date.now() - 30000) },
];

export default function ChatScreen() {
  const navigation = useNavigation<any>();
  const route = useRoute<any>();
  const { threadId = 'support', title = 'Support' } = route.params ?? {};
  const user = useAuthStore((s: any) => s.user);
  const [messages, setMessages] = useState<any[]>(DEMO_MESSAGES);
  const [text, setText] = useState('');
  const listRef = useRef<FlatList>(null);

  useEffect(() => {
    const unsub = onMessages(threadId, (msgs) => {
      if (msgs.length > 0) setMessages(msgs);
      setTimeout(() => listRef.current?.scrollToEnd({ animated: true }), 100);
    });
    return unsub;
  }, [threadId]);

  async function handleSend() {
    if (!text.trim() || !user) return;
    const msg = text.trim();
    setText('');
    // Add to local state immediately for responsiveness
    const newMsg = { id: Date.now().toString(), senderId: user.uid, senderName: user.displayName, text: msg, createdAt: new Date() };
    setMessages(prev => [...prev, newMsg]);
    setTimeout(() => listRef.current?.scrollToEnd({ animated: true }), 100);
    // Send to Firebase
    await sendMessage(threadId, { threadId, senderId: user.uid, senderName: user.displayName, text: msg });
  }

  function formatTime(date: any): string {
    try {
      const d = date?.toDate ? date.toDate() : new Date(date);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch { return ''; }
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* AppBar */}
      <View style={styles.appbar}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <View style={styles.avatarCircle}><Text style={{ fontSize: 18 }}>💬</Text></View>
        <View>
          <Text style={styles.chatTitle}>{title}</Text>
          <View style={styles.onlineRow}>
            <View style={styles.onlineDot} />
            <Text style={styles.onlineSub}>Online</Text>
          </View>
        </View>
      </View>

      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <FlatList
          ref={listRef}
          data={messages}
          keyExtractor={m => m.id}
          contentContainerStyle={{ padding: Spacing.md, gap: 10 }}
          onContentSizeChange={() => listRef.current?.scrollToEnd({ animated: false })}
          renderItem={({ item: m }) => {
            const isMe = m.senderId === user?.uid;
            return (
              <View style={[styles.bubbleRow, isMe && styles.bubbleRowMe]}>
                {!isMe && (
                  <View style={styles.avatarSmall}><Text style={{ fontSize: 12 }}>👤</Text></View>
                )}
                <View style={[styles.bubble, isMe ? styles.bubbleMe : styles.bubbleThem]}>
                  {!isMe && <Text style={styles.senderName}>{m.senderName}</Text>}
                  <Text style={[styles.bubbleText, isMe && styles.bubbleTextMe]}>{m.text}</Text>
                  <Text style={[styles.bubbleTime, isMe && styles.bubbleTimeMe]}>{formatTime(m.createdAt)}</Text>
                </View>
              </View>
            );
          }}
        />

        {/* Input bar */}
        <View style={styles.inputBar}>
          <TextInput
            style={styles.input}
            value={text}
            onChangeText={setText}
            placeholder="Type a message..."
            placeholderTextColor={Colors.textLight}
            multiline
            maxLength={500}
            returnKeyType="send"
            onSubmitEditing={handleSend}
          />
          <TouchableOpacity style={[styles.sendBtn, !text.trim() && styles.sendBtnDisabled]} onPress={handleSend} disabled={!text.trim()}>
            <Text style={styles.sendIcon}>➤</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.lightBg },
  appbar: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: Spacing.md, paddingVertical: 12, backgroundColor: Colors.white, borderBottomWidth: 0.5, borderColor: Colors.border },
  backBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.lightBg, alignItems: 'center', justifyContent: 'center' },
  backArrow: { fontSize: 18, color: Colors.textDark },
  avatarCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center' },
  chatTitle: { fontSize: FontSize.md, fontWeight: '700', color: Colors.textDark },
  onlineRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
  onlineDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: Colors.primary },
  onlineSub: { fontSize: FontSize.xs, color: Colors.primary, fontWeight: '600' },
  bubbleRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 8 },
  bubbleRowMe: { flexDirection: 'row-reverse' },
  avatarSmall: { width: 30, height: 30, borderRadius: 15, backgroundColor: Colors.primaryLight, alignItems: 'center', justifyContent: 'center', marginBottom: 4 },
  bubble: { maxWidth: '75%', borderRadius: Radius.lg, padding: 12, paddingHorizontal: 14 },
  bubbleMe: { backgroundColor: Colors.primary, borderBottomRightRadius: 4 },
  bubbleThem: { backgroundColor: Colors.white, borderBottomLeftRadius: 4, borderWidth: 0.5, borderColor: Colors.border },
  senderName: { fontSize: FontSize.xs, fontWeight: '700', color: Colors.primary, marginBottom: 4 },
  bubbleText: { fontSize: FontSize.sm, color: Colors.textDark, lineHeight: 20 },
  bubbleTextMe: { color: Colors.white },
  bubbleTime: { fontSize: 9, color: Colors.textLight, marginTop: 5, alignSelf: 'flex-end' },
  bubbleTimeMe: { color: 'rgba(255,255,255,0.6)' },
  inputBar: { flexDirection: 'row', alignItems: 'flex-end', gap: 10, padding: Spacing.sm, paddingHorizontal: Spacing.md, backgroundColor: Colors.white, borderTopWidth: 0.5, borderColor: Colors.border },
  input: { flex: 1, minHeight: 44, maxHeight: 100, paddingHorizontal: 14, paddingVertical: 11, backgroundColor: Colors.lightBg, borderRadius: Radius.full, borderWidth: 0.5, borderColor: Colors.border, fontSize: FontSize.md, color: Colors.textDark },
  sendBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center' },
  sendBtnDisabled: { backgroundColor: Colors.border },
  sendIcon: { color: Colors.white, fontSize: 16 },
});

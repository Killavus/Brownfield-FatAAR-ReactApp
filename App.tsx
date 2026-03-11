import { useEffect, useState } from 'react';
import { Text, View, StyleSheet, Button, Pressable } from 'react-native';
import NativePipe from 'react-native-nitro-event-pipe';
import type { Accommodation } from 'react-native-nitro-event-pipe';
import Animated, { useSharedValue } from 'react-native-reanimated';

export default function App() {
  const [accommodations, setAccommodations] = useState<Accommodation[] | null>(
    null
  );

  useEffect(() => {
    NativePipe.onAccommodationMapChange((accomodationMap) => {
      console.log('accomodation map change...');
      setAccommodations(accomodationMap.results);
    });
  }, []);

  const width = useSharedValue(100);
  const handlePress = () => {
    width.value = withSpring(width.value + 50);
  };

  return (
    <View style={styles.container}>
      <Button
        title="Start"
        onPress={() => NativePipe.requestAccommodationMap()}
      />

      {accommodations?.map((accommodation) => (
        <Pressable
          style={{ padding: 12 }}
          key={accommodation.hotelId}
          onPress={() => NativePipe.selectAccommodation(accommodation.hotelId)}
        >
          <Text>{accommodation.name}</Text>
        </Pressable>
      ))}

      <Button title="Refresh" onPress={() => NativePipe.refresh()} />

      <View>
	<Text>Animation test!</Text>
	<Animated.View style={[styles.square, { width }]} />
	<Button title="Press me" onPress={handlePress} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  square: {
    width: 20,
    height: 20,
    backgroundColor: 'red'
  },
});


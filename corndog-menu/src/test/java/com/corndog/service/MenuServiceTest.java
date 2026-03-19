package com.corndog.service;

import com.corndog.model.MenuItem;
import com.corndog.repository.MenuItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MenuServiceTest {

    @Mock
    private MenuItemRepository menuItemRepository;

    @InjectMocks
    private MenuService menuService;

    private MenuItem classicDog;
    private MenuItem chiliDog;

    @BeforeEach
    void setUp() {
        classicDog = new MenuItem("Classic Corn Dog", "Golden battered frank", new BigDecimal("4.99"), "🌭");
        classicDog.setId(1L);

        chiliDog = new MenuItem("Chili Cheese Dog", "Topped with chili and cheese", new BigDecimal("6.49"), "🌶️");
        chiliDog.setId(2L);
    }

    @Nested
    @DisplayName("getAllItems")
    class GetAllItems {

        @Test
        @DisplayName("returns all menu items from repository")
        void returnsAllItems() {
            when(menuItemRepository.findAll()).thenReturn(List.of(classicDog, chiliDog));

            List<MenuItem> items = menuService.getAllItems();

            assertThat(items).hasSize(2);
            assertThat(items).extracting(MenuItem::getName)
                    .containsExactlyInAnyOrder("Classic Corn Dog", "Chili Cheese Dog");
            verify(menuItemRepository, times(1)).findAll();
        }

        @Test
        @DisplayName("returns empty list when no items exist")
        void returnsEmptyList() {
            when(menuItemRepository.findAll()).thenReturn(Collections.emptyList());

            List<MenuItem> items = menuService.getAllItems();

            assertThat(items).isEmpty();
        }

        @Test
        @DisplayName("delegates to repository exactly once")
        void delegatesToRepository() {
            when(menuItemRepository.findAll()).thenReturn(List.of(classicDog));

            menuService.getAllItems();

            verify(menuItemRepository, times(1)).findAll();
            verifyNoMoreInteractions(menuItemRepository);
        }
    }

    @Nested
    @DisplayName("getItem")
    class GetItem {

        @Test
        @DisplayName("returns item when found")
        void returnsItemWhenFound() {
            when(menuItemRepository.findById(1L)).thenReturn(Optional.of(classicDog));

            MenuItem result = menuService.getItem(1L);

            assertThat(result.getName()).isEqualTo("Classic Corn Dog");
            assertThat(result.getPrice()).isEqualByComparingTo(new BigDecimal("4.99"));
        }

        @Test
        @DisplayName("throws RuntimeException when item not found")
        void throwsWhenNotFound() {
            when(menuItemRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> menuService.getItem(999L))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("999");
        }

        @Test
        @DisplayName("exception message includes the missing item id")
        void exceptionIncludesId() {
            when(menuItemRepository.findById(42L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> menuService.getItem(42L))
                    .hasMessageContaining("42");
        }
    }

    // ---- FLAKY TESTS (intentional — for Datadog Test Visibility demo) ----

    @Nested
    @DisplayName("performance constraints")
    class PerformanceConstraints {

        @Test
        @DisplayName("getAllItems completes within acceptable latency")
        void getAllItemsLatency() {
            when(menuItemRepository.findAll()).thenReturn(List.of(classicDog, chiliDog));

            long start = System.nanoTime();
            menuService.getAllItems();
            long elapsed = TimeUnit.NANOSECONDS.toMicros(System.nanoTime() - start);

            // Tight threshold that GC pauses or CPU contention can bust
            assertThat(elapsed)
                    .as("getAllItems should complete within 500µs")
                    .isLessThan(500);
        }
    }

    @Nested
    @DisplayName("concurrent access")
    class ConcurrentAccess {

        @Test
        @DisplayName("handles concurrent getItem calls without error")
        void concurrentGetItem() throws InterruptedException {
            when(menuItemRepository.findById(1L)).thenReturn(Optional.of(classicDog));

            int threadCount = 50;
            ExecutorService executor = Executors.newFixedThreadPool(threadCount);
            CountDownLatch latch = new CountDownLatch(threadCount);
            AtomicReference<Throwable> failure = new AtomicReference<>();

            for (int i = 0; i < threadCount; i++) {
                executor.submit(() -> {
                    try {
                        MenuItem item = menuService.getItem(1L);
                        // Race-condition–prone: compare object identity instead of equality
                        if (item.getName().length() != "Classic Corn Dog".length()) {
                            throw new AssertionError("Unexpected name length");
                        }
                    } catch (Throwable t) {
                        failure.compareAndSet(null, t);
                    } finally {
                        latch.countDown();
                    }
                });
            }

            // Tight timeout — thread pool starvation on CI can exceed this
            boolean finished = latch.await(200, TimeUnit.MILLISECONDS);
            executor.shutdownNow();

            assertThat(finished)
                    .as("All threads should finish within 200ms")
                    .isTrue();
            assertThat(failure.get()).isNull();
        }
    }

    @Nested
    @DisplayName("item ordering")
    class ItemOrdering {

        @Test
        @DisplayName("menu items are returned in expected display order")
        void menuItemsReturnedInOrder() {
            // Simulate a repo that returns items in non-deterministic order
            List<MenuItem> items;
            if (System.nanoTime() % 2 == 0) {
                items = List.of(classicDog, chiliDog);
            } else {
                items = List.of(chiliDog, classicDog);
            }
            when(menuItemRepository.findAll()).thenReturn(items);

            List<MenuItem> result = menuService.getAllItems();

            // Asserts strict ordering — flaky because the source order varies
            assertThat(result).extracting(MenuItem::getName)
                    .containsExactly("Classic Corn Dog", "Chili Cheese Dog");
        }
    }
}

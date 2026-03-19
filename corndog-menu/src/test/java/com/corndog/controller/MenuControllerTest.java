package com.corndog.controller;

import com.corndog.model.MenuItem;
import com.corndog.service.MenuService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(MenuController.class)
class MenuControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
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
    @DisplayName("GET /api/menu")
    class GetAllMenu {

        @Test
        @DisplayName("returns 200 with list of menu items")
        void returnsMenuItems() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of(classicDog, chiliDog));

            mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(2)))
                    .andExpect(jsonPath("$[0].name").value("Classic Corn Dog"))
                    .andExpect(jsonPath("$[1].name").value("Chili Cheese Dog"));
        }

        @Test
        @DisplayName("returns 200 with empty array when no items")
        void returnsEmptyArray() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of());

            mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(0)));
        }

        @Test
        @DisplayName("response contains correct price values")
        void containsCorrectPrices() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of(classicDog));

            mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].price").value(4.99));
        }

        @Test
        @DisplayName("response content type is application/json")
        void contentTypeIsJson() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of(classicDog));

            mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andExpect(content().contentTypeCompatibleWith("application/json"));
        }
    }

    @Nested
    @DisplayName("GET /api/menu/{id}")
    class GetItemById {

        @Test
        @DisplayName("returns 200 with item when found")
        void returnsItem() throws Exception {
            when(menuService.getItem(1L)).thenReturn(classicDog);

            mockMvc.perform(get("/api/menu/1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.name").value("Classic Corn Dog"))
                    .andExpect(jsonPath("$.emoji").value("🌭"));
        }

        @Test
        @DisplayName("throws when item not found")
        void throwsWhenNotFound() {
            when(menuService.getItem(999L)).thenThrow(new RuntimeException("Menu item not found: 999"));

            assertThatThrownBy(() -> mockMvc.perform(get("/api/menu/999")))
                    .hasCauseInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Menu item not found: 999");
        }
    }

    // ---- FLAKY TESTS (intentional — for Datadog Test Visibility demo) ----

    @Nested
    @DisplayName("response time SLA")
    class ResponseTimeSla {

        @Test
        @DisplayName("GET /api/menu responds within 50ms SLA")
        void menuEndpointMeetsSla() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of(classicDog, chiliDog));

            long start = System.nanoTime();
            MvcResult result = mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andReturn();
            long elapsedMs = (System.nanoTime() - start) / 1_000_000;

            // Very tight SLA — first-request JIT warmup or GC can bust this
            if (elapsedMs > 50) {
                throw new AssertionError(
                        "SLA breach: GET /api/menu took " + elapsedMs + "ms (limit: 50ms)");
            }
        }
    }

    @Nested
    @DisplayName("response body size")
    class ResponseBodySize {

        @Test
        @DisplayName("menu payload is within size budget")
        void payloadWithinBudget() throws Exception {
            when(menuService.getAllItems()).thenReturn(List.of(classicDog, chiliDog));

            MvcResult result = mockMvc.perform(get("/api/menu"))
                    .andExpect(status().isOk())
                    .andReturn();

            int bodyLength = result.getResponse().getContentAsString().length();

            // Tight budget that emoji encoding differences can bust.
            // UTF-8 emoji byte counts vary by platform/JDK version.
            assertThat(bodyLength)
                    .as("Payload should be under 250 chars")
                    .isLessThan(250);
        }
    }
}
